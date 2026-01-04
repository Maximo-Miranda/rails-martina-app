# frozen_string_literal: true

module Documents
  class DeleteDocumentJob < ApplicationJob
    queue_as :default

    retry_on Gemini::DocumentService::DeleteError, wait: :polynomially_longer, attempts: 3
    discard_on ActiveRecord::RecordNotFound

    def perform(document_id, gemini_document_path)
      document = Document.find(document_id)

      # Delete from Gemini if it was synced
      if gemini_document_path.present?
        Gemini::DocumentService.delete(gemini_document_path)
      end

      # Update store counters before soft-deleting
      if document.active?
        store = document.gemini_file_search_store
        store.decrement!(:active_documents_count)
        store.decrement!(:size_bytes, document.size_bytes)
      end

      document.discard!

      Rails.configuration.event_store.publish(
        Documents::Deleted.new(data: { document_id: document.id }),
        stream_name: "Document$#{document.id}"
      )
    rescue Gemini::DocumentService::DeleteError => e
      Rails.logger.error("[DeleteDocumentJob] Failed for document #{document_id}: #{e.message}")
      raise
    end
  end
end
