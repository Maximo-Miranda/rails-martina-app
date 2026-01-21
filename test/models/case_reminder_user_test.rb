# frozen_string_literal: true

require "test_helper"

class CaseReminderUserTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @reminder = case_reminders(:audiencia_reminder)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "valid case reminder user" do
    client = users(:client_user)
    reminder_user = CaseReminderUser.new(
      case_reminder: @reminder,
      user: client
    )

    assert reminder_user.valid?
  end

  test "validates user_id uniqueness scoped to case_reminder_id" do
    existing = case_reminder_users(:reminder_user_one)
    duplicate = CaseReminderUser.new(
      case_reminder: existing.case_reminder,
      user: existing.user
    )

    assert duplicate.invalid?
    assert_includes duplicate.errors.attribute_names, :user_id
  end

  test "allows same user on different reminder" do
    other_reminder = case_reminders(:termino_reminder)
    reminder_user = CaseReminderUser.new(
      case_reminder: other_reminder,
      user: @coworker
    )

    assert reminder_user.valid?
  end

  test "scope pending returns unacknowledged users" do
    pending = CaseReminderUser.pending

    assert pending.all? { |ru| !ru.acknowledged? }
  end

  test "scope acknowledged_users returns acknowledged users" do
    acknowledged = CaseReminderUser.acknowledged_users

    assert acknowledged.all?(&:acknowledged?)
  end

  test "acknowledge! marks user as acknowledged with timestamp" do
    reminder_user = case_reminder_users(:reminder_user_one)

    assert_not reminder_user.acknowledged?
    assert_nil reminder_user.acknowledged_at

    freeze_time do
      reminder_user.acknowledge!

      assert reminder_user.acknowledged?
      assert_equal Time.current, reminder_user.acknowledged_at
    end
  end

  test "acknowledge! does nothing if already acknowledged" do
    reminder_user = case_reminder_users(:reminder_user_acknowledged)
    original_time = reminder_user.acknowledged_at

    reminder_user.acknowledge!

    assert_equal original_time, reminder_user.acknowledged_at
  end
end
