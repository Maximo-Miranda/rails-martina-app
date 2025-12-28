# frozen_string_literal: true

require "test_helper"

class Gemini::CreateStoreJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @pending_store = gemini_file_search_stores(:pending_store)
    @active_store = gemini_file_search_stores(:active_store)
    @event_store = Rails.configuration.event_store
  end

  test "creates store in Gemini API and updates local record" do
    VCR.use_cassette("gemini/create_store_success") do
      Gemini::CreateStoreJob.perform_now(@pending_store.id)
    end

    @pending_store.reload
    assert_equal "active", @pending_store.status
    assert_match(/fileSearchStores\//, @pending_store.gemini_store_name)
    assert_nil @pending_store.error_message
  end

  test "publishes StoreCreated event on success" do
    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreCreated ])

    VCR.use_cassette("gemini/create_store_success") do
      Gemini::CreateStoreJob.perform_now(@pending_store.id)
    end

    assert_equal 1, events.size
    assert_equal @pending_store.id, events.first.data[:store_id]
  end

  test "skips if store not found" do
    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreCreated ])

    Gemini::CreateStoreJob.perform_now(-1)

    assert_empty events, "Should not publish StoreCreated event when store not found"
  end

  test "skips if store is already active" do
    original_status = @active_store.status
    original_name = @active_store.gemini_store_name

    Gemini::CreateStoreJob.perform_now(@active_store.id)

    @active_store.reload
    assert_equal original_status, @active_store.status
    assert_equal original_name, @active_store.gemini_store_name
  end
end
