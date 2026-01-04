# frozen_string_literal: true

module Documents
  class UploadFailed < RailsEventStore::Event
    # data: { document_id:, error_message: }
  end
end
