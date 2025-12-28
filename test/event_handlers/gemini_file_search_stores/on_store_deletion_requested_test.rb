# frozen_string_literal: true

require "test_helper"
require_relative "../../../app/event_handlers/gemini_file_search_stores/on_store_deletion_requested"

class OnStoreDeletionRequestedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @active_store = gemini_file_search_stores(:active_store)
  end

  test "enqueues DeleteStoreJob" do
    event = Gemini::StoreDeletionRequested.new(data: {
      store_id: @active_store.id,
      project_id: @active_store.project_id,
      gemini_store_name: @active_store.gemini_store_name,
    })

    assert_enqueued_with(job: Gemini::DeleteStoreJob, args: [ @active_store.id ]) do
      GeminiFileSearchStores::OnStoreDeletionRequested.new.call(event)
    end
  end
end
