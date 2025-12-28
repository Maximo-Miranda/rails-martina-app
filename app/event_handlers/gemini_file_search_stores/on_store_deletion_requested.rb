# frozen_string_literal: true

module GeminiFileSearchStores
  class OnStoreDeletionRequested
    def call(event)
      Gemini::DeleteStoreJob.perform_later(event.data[:store_id])
    end
  end
end
