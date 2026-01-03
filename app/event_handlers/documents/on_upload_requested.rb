# frozen_string_literal: true

module Documents
  class OnUploadRequested
    def call(event)
      Documents::UploadDocumentJob.perform_later(event.data[:document_id])
    end
  end
end
