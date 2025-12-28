# frozen_string_literal: true

module Gemini
  class StoreDeleted < RailsEventStore::Event
    # data: { store_id:, project_id:, gemini_store_name: }
  end
end
