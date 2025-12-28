# frozen_string_literal: true

module Projects
  class ProjectDiscarded < RailsEventStore::Event
    # data: { project_id:, user_id:, gemini_store_id: }
  end
end
