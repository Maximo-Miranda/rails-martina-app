# frozen_string_literal: true

require "test_helper"

class CaseReminderTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @legal_case = legal_cases(:legal_case_one)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "valid reminder" do
    reminder = CaseReminder.new(
      legal_case: @legal_case,
      created_by: @user,
      title: "Test Reminder",
      reminder_type: :audiencia,
      reminder_at: 1.day.from_now
    )

    assert reminder.valid?
  end

  test "requires custom_type when reminder_type is otro" do
    reminder = CaseReminder.new(
      legal_case: @legal_case,
      created_by: @user,
      title: "Custom Reminder",
      reminder_type: :otro,
      reminder_at: 1.day.from_now
    )

    assert reminder.invalid?
    assert_includes reminder.errors.attribute_names, :custom_type

    reminder.custom_type = "Tipo Personalizado"
    assert reminder.valid?
  end

  test "display_type returns custom_type for otro type" do
    reminder = CaseReminder.new(
      reminder_type: :otro,
      custom_type: "Mi Tipo Custom"
    )

    assert_equal "Mi Tipo Custom", reminder.display_type
  end

  test "display_type returns humanized type for regular types" do
    reminder = CaseReminder.new(reminder_type: :audiencia)

    assert_equal "Audiencia", reminder.display_type
  end

  test "acknowledged? returns true when any user acknowledged" do
    reminder = case_reminders(:reminder_past)

    assert reminder.acknowledged?
  end

  test "acknowledged? returns false when no user acknowledged" do
    reminder = case_reminders(:audiencia_reminder)

    assert_not reminder.acknowledged?
  end

  test "acknowledge_for! marks user as acknowledged" do
    reminder = case_reminders(:audiencia_reminder)
    reminder_user = case_reminder_users(:reminder_user_one)

    assert_not reminder_user.acknowledged?

    reminder.acknowledge_for!(@user)
    reminder_user.reload

    assert reminder_user.acknowledged?
    assert_not_nil reminder_user.acknowledged_at
  end

  test "scope upcoming returns future reminders" do
    upcoming = CaseReminder.upcoming

    assert upcoming.all? { |r| r.reminder_at > Time.current }
  end

  test "scope past returns past reminders" do
    past = CaseReminder.past

    assert past.all? { |r| r.reminder_at <= Time.current }
  end

  test "schedules notification jobs on create" do
    assert_enqueued_jobs 4, only: LegalCases::SendSingleReminderNotificationJob do
      CaseReminder.create!(
        legal_case: @legal_case,
        created_by: @user,
        title: "New Reminder",
        reminder_type: :audiencia,
        reminder_at: 4.days.from_now
      )
    end
  end

  test "does not schedule jobs for past notification times" do
    # Reminder in 30 minutes should only schedule 0 jobs (all windows are past)
    assert_enqueued_jobs 0, only: LegalCases::SendSingleReminderNotificationJob do
      CaseReminder.create!(
        legal_case: @legal_case,
        created_by: @user,
        title: "Urgent Reminder",
        reminder_type: :audiencia,
        reminder_at: 30.minutes.from_now
      )
    end
  end

  test "reschedules jobs when reminder_at changes" do
    reminder = CaseReminder.create!(
      legal_case: @legal_case,
      created_by: @user,
      title: "Test Reminder",
      reminder_type: :audiencia,
      reminder_at: 4.days.from_now
    )

    # Update reminder_at should reschedule
    assert_enqueued_jobs 4, only: LegalCases::SendSingleReminderNotificationJob do
      reminder.update!(reminder_at: 5.days.from_now)
    end
  end
end
