# frozen_string_literal: true

module LegalCases
  class EnableCaseDocumentAiService
    class Error < StandardError; end
    class StoreNotFoundError < Error; end
    class FileNotAttachedError < Error; end
    class UnsupportedContentTypeError < Error; end

    Result = Data.define(:success?, :document, :error).freeze

    def self.call(case_document:, user:)
      new(case_document:, user:).call
    end

    def initialize(case_document:, user:)
      @case_document = case_document
      @user = user
    end

    def call
      validate!

      document = create_document
      case_document.update_column(:document_id, document.id)

      Documents::UploadDocumentJob.perform_later(document.id) if document.pending?

      Result.new(success?: true, document:, error: nil)
    rescue Error => e
      Result.new(success?: false, document: nil, error: e.message)
    end

    private

    attr_reader :case_document, :user

    def validate!
      raise FileNotAttachedError, I18n.t("legal_cases.services.file_not_attached") unless case_document.file.attached?
      raise StoreNotFoundError, I18n.t("legal_cases.services.store_not_found") unless store.present?
      raise UnsupportedContentTypeError, I18n.t("legal_cases.services.unsupported_content_type") unless supported_content_type?
    end

    def create_document
      find_existing_document || create_new_document
    end

    def find_existing_document
      file_hash = case_document.file.blob.open { |f| Digest::SHA256.file(f.path).hexdigest }

      Document.kept
              .where(gemini_file_search_store: store)
              .where(file_hash:)
              .first
    end

    def create_new_document
      Document.create!(
        gemini_file_search_store: store,
        uploaded_by: user,
        project: project,
        display_name: case_document.name,
        file: case_document.file.blob,
        custom_metadata: build_metadata
      )
    end

    def blob_to_attachable
      {
        io: StringIO.new(case_document.file.download),
        filename: case_document.file.filename,
        content_type: case_document.file.content_type,
      }
    end

    def build_metadata
      {
        source: "legal_case",
        legal_case_id: legal_case.id.to_s,
        legal_case_number: legal_case.case_number,
        case_notebook_id: case_document.case_notebook_id.to_s,
        case_notebook_name: case_document.case_notebook.display_name,
        document_type: case_document.document_type,
        document_date: case_document.document_date&.iso8601,
        issuer: case_document.issuer,
      }.compact
    end

    def store
      @store ||= project&.gemini_file_search_store
    end

    def project
      @project ||= legal_case.project
    end

    def legal_case
      @legal_case ||= case_document.legal_case
    end

    def supported_content_type?
      Document::SUPPORTED_CONTENT_TYPES.key?(case_document.file.content_type)
    end
  end
end
