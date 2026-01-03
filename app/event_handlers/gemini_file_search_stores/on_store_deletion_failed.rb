# frozen_string_literal: true

module GeminiFileSearchStores
  class OnStoreDeletionFailed
    def call(event)
      store = GeminiFileSearchStore.find(event.data[:store_id])
      user = User.find_by(id: event.data[:user_id])
      return unless user

      GeminiStoreDeletionFailedNotifier
        .with(store: store, error: event.data[:error_message])
        .deliver(user)
    end
  end
end
