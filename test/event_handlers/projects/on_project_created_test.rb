# frozen_string_literal: true

require "test_helper"
require_relative "../../../app/event_handlers/projects/on_project_created"

class OnProjectCreatedTest < ActiveSupport::TestCase
  def setup
    @test_project = projects(:test_project)
    @event_store = Rails.configuration.event_store
  end

  test "creates a pending store for the project" do
    new_project = Project.create!(
      name: "New Project",
      slug: "new-project",
      description: "Test project",
      user: users(:confirmed_user)
    )

    event = Projects::ProjectCreated.new(data: {
      project_id: new_project.id,
      project_name: new_project.name,
    })

    assert_difference "GeminiFileSearchStore.count", 1 do
      Projects::OnProjectCreated.new.call(event)
    end

    store = GeminiFileSearchStore.last
    assert_equal new_project.id, store.project_id
    assert_equal new_project.name, store.display_name
    assert_equal "pending", store.status

    store.destroy
    new_project.destroy
  end

  test "publishes StoreCreationRequested event" do
    new_project = Project.create!(
      name: "Event Project",
      slug: "event-project",
      description: "Test",
      user: users(:confirmed_user)
    )

    events = []
    @event_store.subscribe(->(event) { events << event }, to: [ Gemini::StoreCreationRequested ])

    event = Projects::ProjectCreated.new(data: {
      project_id: new_project.id,
      project_name: new_project.name,
    })

    Projects::OnProjectCreated.new.call(event)

    assert_equal 1, events.size
    assert_equal new_project.id, events.first.data[:project_id]

    GeminiFileSearchStore.last.destroy
    new_project.destroy
  end

  test "does nothing if project not found" do
    event = Projects::ProjectCreated.new(data: {
      project_id: -1,
      project_name: "Non existent",
    })

    assert_no_difference "GeminiFileSearchStore.count" do
      Projects::OnProjectCreated.new.call(event)
    end
  end
end
