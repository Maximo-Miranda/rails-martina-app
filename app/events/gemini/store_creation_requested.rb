# frozen_string_literal: true

module Gemini
  class StoreCreationRequested < RailsEventStore::Event
    # data: { store_id:, project_id:, display_name: }
  end
end
