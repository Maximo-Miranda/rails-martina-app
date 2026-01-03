# frozen_string_literal: true

module Documents
  class OnUploadFailed
    def call(event)
      document = Document.find(event.data[:document_id])

      DocumentUploadFailedNotifier
        .with(document: document)
        .deliver(document.uploaded_by)
    end
  end
end
