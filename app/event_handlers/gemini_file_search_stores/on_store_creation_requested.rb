# frozen_string_literal: true

module GeminiFileSearchStores
  class OnStoreCreationRequested
    def call(event)
      Gemini::CreateStoreJob.perform_later(event.data[:store_id], event.data[:user_id])
    end
  end
end
