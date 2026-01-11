# frozen_string_literal: true

module Documents
  class UploadDocumentJob < ApplicationJob
    queue_as :default

    retry_on Gemini::DocumentService::UploadError, wait: :polynomially_longer, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(document_id)
      document = Document.find(document_id)
      return if document.active? || document.deleted?

      document.update!(status: :processing)

      with_tempfile(document) do |tempfile|
        result = upload_to_gemini(document, tempfile)
        mark_as_active(document, result)
        publish_success_event(document, result)
      end
    rescue => e
      handle_failure(document, e)
      raise
    end

    private

    def with_tempfile(document)
      extension = Document.extension_for_content_type(document.content_type) || ""
      tempfile = Tempfile.new([ document.file_hash, extension ])
      tempfile.binmode
      tempfile.write(document.file.download)
      tempfile.rewind
      yield tempfile
    ensure
      tempfile&.close
      tempfile&.unlink
    end

    def upload_to_gemini(document, tempfile)
      Gemini::DocumentService.upload(
        file_path: tempfile.path,
        store_remote_id: document.gemini_file_search_store.gemini_store_name,
        display_name: document.display_name,
        mime_type: document.content_type,
        custom_metadata: document.custom_metadata
      )
    end

    def mark_as_active(document, result)
      document.update!(
        status: :active,
        remote_id: result[:remote_id],
        gemini_document_path: result[:gemini_document_path],
        error_message: nil
      )
    end

    def publish_success_event(document, result)
      Rails.configuration.event_store.publish(
        Documents::Uploaded.new(data: {
          document_id: document.id,
          remote_id: result[:remote_id],
          gemini_document_path: result[:gemini_document_path],
          size_bytes: result[:size_bytes],
        }),
        stream_name: "Document$#{document.id}"
      )
    end

    def handle_failure(document, error)
      Rails.logger.error("[UploadDocumentJob] Failed for document #{document.id}: #{error.message}")

      document.update!(status: :failed, error_message: error.message)

      Rails.configuration.event_store.publish(
        Documents::UploadFailed.new(data: {
          document_id: document.id,
          error_message: error.message,
        }),
        stream_name: "Document$#{document.id}"
      )
    end
  end
end
