# frozen_string_literal: true

module Documents
  class OnDeleted
    def call(event)
      document = Document.unscoped.find(event.data[:document_id])

      DocumentDeletedNotifier
        .with(document: document)
        .deliver(document.uploaded_by)
    end
  end
end
