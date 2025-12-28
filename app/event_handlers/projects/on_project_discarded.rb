# frozen_string_literal: true

module Projects
  class OnProjectDiscarded
    def call(event)
      store = GeminiFileSearchStore.find_by(project_id: event.data[:project_id])
      return unless store
      return if store.discarded?

      Rails.configuration.event_store.publish(
        Gemini::StoreDeletionRequested.new(data: {
          store_id: store.id,
          project_id: event.data[:project_id],
          gemini_store_name: store.gemini_store_name,
        }),
        stream_name: "GeminiFileSearchStore$#{store.id}"
      )
    end
  end
end
