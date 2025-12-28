# frozen_string_literal: true

module Gemini
  class StoreDeletionRequested < RailsEventStore::Event
    # data: { store_id:, project_id:, gemini_store_name: }
  end
end
