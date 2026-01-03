# frozen_string_literal: true

module Documents
  class OnDeletionRequested
    def call(event)
      Documents::DeleteDocumentJob.perform_later(
        event.data[:document_id],
        event.data[:gemini_document_path]
      )
    end
  end
end
