# frozen_string_literal: true

module Gemini
  class StoreCreated < RailsEventStore::Event
    # data: { store_id:, project_id:, gemini_store_name:, display_name: }
  end
end
