# frozen_string_literal: true

module Documents
  class UploadRequested < RailsEventStore::Event
    # data: { document_id:, store_id:, user_id:, display_name: }
  end
end
