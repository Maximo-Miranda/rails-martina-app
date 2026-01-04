# frozen_string_literal: true

require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: JSON)
  )

  # Subscribe event handlers using strings to avoid autoload issues
  Rails.configuration.event_store.tap do |store|
    # Gemini File Search Store events
    store.subscribe(
      ->(event) { Projects::OnProjectCreated.new.call(event) },
      to: [ Projects::ProjectCreated ]
    )

    store.subscribe(
      ->(event) { Projects::OnProjectDiscarded.new.call(event) },
      to: [ Projects::ProjectDiscarded ]
    )

    store.subscribe(
      ->(event) { GeminiFileSearchStores::OnStoreCreationRequested.new.call(event) },
      to: [ Gemini::StoreCreationRequested ]
    )

    store.subscribe(
      ->(event) { GeminiFileSearchStores::OnStoreDeletionRequested.new.call(event) },
      to: [ Gemini::StoreDeletionRequested ]
    )

    store.subscribe(
      ->(event) { GeminiFileSearchStores::OnStoreCreated.new.call(event) },
      to: [ Gemini::StoreCreated ]
    )

    store.subscribe(
      ->(event) { GeminiFileSearchStores::OnStoreCreationFailed.new.call(event) },
      to: [ Gemini::StoreCreationFailed ]
    )

    store.subscribe(
      ->(event) { GeminiFileSearchStores::OnStoreDeleted.new.call(event) },
      to: [ Gemini::StoreDeleted ]
    )

    store.subscribe(
      ->(event) { GeminiFileSearchStores::OnStoreDeletionFailed.new.call(event) },
      to: [ Gemini::StoreDeletionFailed ]
    )

    # Document events
    store.subscribe(
      ->(event) { Documents::OnUploadRequested.new.call(event) },
      to: [ Documents::UploadRequested ]
    )

    store.subscribe(
      ->(event) { Documents::OnUploaded.new.call(event) },
      to: [ Documents::Uploaded ]
    )

    store.subscribe(
      ->(event) { Documents::OnUploadFailed.new.call(event) },
      to: [ Documents::UploadFailed ]
    )

    store.subscribe(
      ->(event) { Documents::OnDeletionRequested.new.call(event) },
      to: [ Documents::DeletionRequested ]
    )

    store.subscribe(
      ->(event) { Documents::OnDeleted.new.call(event) },
      to: [ Documents::Deleted ]
    )
  end
end

# Browser UI for viewing events (super_admin only)
Rails.configuration.event_store_browser_enabled = true
