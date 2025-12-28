# frozen_string_literal: true

require "test_helper"
require_relative "../../../app/event_handlers/projects/on_project_discarded"

class OnProjectDiscardedTest < ActiveSupport::TestCase
  def setup
    @test_project = projects(:test_project)
    @active_store = gemini_file_search_stores(:active_store)
    @event_store = Rails.configuration.event_store
  end

  test "publishes StoreDeletionRequested event when project has store" do
    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreDeletionRequested ])

    event = Projects::ProjectDiscarded.new(data: {
      project_id: @test_project.id,
      project_name: @test_project.name,
    })

    Projects::OnProjectDiscarded.new.call(event)

    assert_equal 1, events.size
    assert_equal @active_store.id, events.first.data[:store_id]
    assert_equal @test_project.id, events.first.data[:project_id]
  end

  test "does nothing if project has no store" do
    new_project = Project.create!(
      name: "No Store Project",
      slug: "no-store-project",
      description: "Test",
      user: users(:confirmed_user)
    )

    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreDeletionRequested ])

    event = Projects::ProjectDiscarded.new(data: {
      project_id: new_project.id,
      project_name: new_project.name,
    })

    Projects::OnProjectDiscarded.new.call(event)

    assert_empty events

    new_project.destroy
  end

  test "does nothing if store is already discarded" do
    @deleted_store = gemini_file_search_stores(:deleted_store)

    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreDeletionRequested ])

    event = Projects::ProjectDiscarded.new(data: {
      project_id: @deleted_store.project_id,
      project_name: "Deleted",
    })

    Projects::OnProjectDiscarded.new.call(event)

    assert_empty events
  end
end
