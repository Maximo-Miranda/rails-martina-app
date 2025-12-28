# frozen_string_literal: true

module Projects
  class ProjectCreated < RailsEventStore::Event
    # data: { project_id:, user_id:, name:, slug: }
  end
end
