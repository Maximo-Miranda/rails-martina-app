# frozen_string_literal: true

module Gemini
  class StoreCreationFailed < RailsEventStore::Event
    # data: { store_id:, project_id:, error_message: }
  end
end
