# frozen_string_literal: true

module Gemini
  class StoreDeletionFailed < RailsEventStore::Event
    # data: { store_id:, project_id:, gemini_store_name:, error_message: }
  end
end
