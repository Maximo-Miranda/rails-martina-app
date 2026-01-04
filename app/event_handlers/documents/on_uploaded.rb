# frozen_string_literal: true

module Documents
  class OnUploaded
    def call(event)
      document = Document.find(event.data[:document_id])

      DocumentUploadedNotifier
        .with(document: document)
        .deliver(document.uploaded_by)
    end
  end
end
