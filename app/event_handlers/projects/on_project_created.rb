# frozen_string_literal: true

module Projects
  class OnProjectCreated
    def call(event)
      project = Project.find_by(id: event.data[:project_id])
      return unless project

      store = GeminiFileSearchStore.create!(
        project: project,
        display_name: project.name,
        status: :pending
      )

      Rails.configuration.event_store.publish(
        Gemini::StoreCreationRequested.new(data: {
          store_id: store.id,
          project_id: project.id,
          display_name: store.display_name,
        }),
        stream_name: "GeminiFileSearchStore$#{store.id}"
      )
    end
  end
end
