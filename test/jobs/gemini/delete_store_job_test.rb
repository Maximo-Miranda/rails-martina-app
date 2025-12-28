# frozen_string_literal: true

require "test_helper"

class Gemini::DeleteStoreJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @active_store = gemini_file_search_stores(:active_store)
    @pending_store = gemini_file_search_stores(:pending_store)
    @deleted_store = gemini_file_search_stores(:deleted_store)
    @event_store = Rails.configuration.event_store
  end

  test "skips if store not found" do
    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreDeleted ])

    Gemini::DeleteStoreJob.perform_now(-1)

    assert_empty events, "Should not publish StoreDeleted event when store not found"
  end

  test "skips if store is already discarded" do
    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreDeleted ])

    initial_status = @deleted_store.status
    initial_discarded_at = @deleted_store.deleted_at

    Gemini::DeleteStoreJob.perform_now(@deleted_store.id)

    assert_empty events, "Should not publish StoreDeleted event when store already discarded"

    @deleted_store.reload
    assert_equal initial_status, @deleted_store.status, "Status should not change"
    assert_equal initial_discarded_at, @deleted_store.deleted_at, "discarded_at should not change"
  end

  test "skips Gemini API call if no gemini_store_name" do
    @pending_store.update!(gemini_store_name: nil)

    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreDeleted ])

    Gemini::DeleteStoreJob.perform_now(@pending_store.id)

    @pending_store.reload
    assert @pending_store.discarded?
    assert_equal "deleted", @pending_store.status
    assert_equal 1, events.size
    assert_nil events.first.data[:gemini_store_name]
  end
end
