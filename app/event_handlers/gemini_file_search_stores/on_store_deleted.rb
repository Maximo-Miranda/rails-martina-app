# frozen_string_literal: true

module GeminiFileSearchStores
  class OnStoreDeleted
    def call(event)
      store = GeminiFileSearchStore.find(event.data[:store_id])
      user = User.find_by(id: event.data[:user_id])
      return unless user

      GeminiStoreDeletedNotifier
        .with(store: store)
        .deliver(user)
    end
  end
end
