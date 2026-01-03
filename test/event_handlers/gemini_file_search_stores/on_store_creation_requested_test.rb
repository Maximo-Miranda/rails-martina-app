# frozen_string_literal: true

require "test_helper"
require_relative "../../../app/event_handlers/gemini_file_search_stores/on_store_creation_requested"

class OnStoreCreationRequestedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @pending_store = gemini_file_search_stores(:pending_store)
  end

  test "enqueues CreateStoreJob" do
    event = Gemini::StoreCreationRequested.new(data: {
      store_id: @pending_store.id,
      project_id: @pending_store.project_id,
      display_name: @pending_store.display_name,
    })

    assert_enqueued_with(job: Gemini::CreateStoreJob, args: [ @pending_store.id, nil ]) do
      GeminiFileSearchStores::OnStoreCreationRequested.new.call(event)
    end
  end
end
