# frozen_string_literal: true

module LegalCases
  class DisableCaseDocumentAiService
    class Error < StandardError; end
    class NotEnabledError < Error; end

    Result = Data.define(:success?, :error).freeze

    def self.call(case_document:)
      new(case_document:).call
    end

    def initialize(case_document:)
      @case_document = case_document
    end

    def call
      validate!

      document = case_document.document
      case_document.update_column(:document_id, nil)

      # Soft delete the document, which triggers Gemini deletion via events
      document.discard

      Result.new(success?: true, error: nil)
    rescue Error => e
      Result.new(success?: false, error: e.message)
    end

    private

    attr_reader :case_document

    def validate!
      raise NotEnabledError, I18n.t("legal_cases.services.ai_not_enabled") unless case_document.ai_enabled?
    end
  end
end
