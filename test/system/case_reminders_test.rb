# frozen_string_literal: true

require "application_system_test_case"

class CaseRemindersTest < ApplicationSystemTestCase
  setup do
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @project = projects(:test_project)
    @legal_case = legal_cases(:legal_case_one)
    @reminder = case_reminders(:audiencia_reminder)
  end

  test "owner can create case reminder" do
    sign_in_with_form(@owner)
    navigate_to_legal_case(@legal_case)

    # Go to reminders tab
    find("[data-testid='legal-case-tab-reminders']").click
    assert_selector "[data-testid='legal-case-btn-add-reminder']", wait: 5

    find("[data-testid='legal-case-btn-add-reminder']").click
    # Navigates to CaseReminders/Form.vue which uses "case-reminders-*" selectors
    assert_selector "[data-testid='case-reminders-input-title']", wait: 5

    # Fill form
    fill_in_field "[data-testid='case-reminders-input-title'] input", with: "Recordatorio de Test"

    find("[data-testid='case-reminders-input-type']").click
    find(".v-list-item", text: /Audiencia/i).click

    fill_in_field "[data-testid='case-reminders-input-description'] textarea", with: "Descripción del recordatorio de prueba"

    # datetime-local inputs require ISO format: YYYY-MM-DDTHH:MM
    reminder_datetime = 3.days.from_now.strftime("%Y-%m-%dT%H:%M")
    fill_in_field "[data-testid='case-reminders-input-datetime'] input", with: reminder_datetime

    fill_in_field "[data-testid='case-reminders-input-location'] input", with: "Sala de Test"

    find("[data-testid='case-reminders-btn-submit']").click

    # Wait for flash message confirming creation
    assert_selector ".flash-snackbar", wait: 10
    assert_text "Recordatorio de Test", wait: 10

    # Verify creation
    reminder = @legal_case.case_reminders.find_by(title: "Recordatorio de Test")
    assert_not_nil reminder
    assert_equal "audiencia", reminder.reminder_type
  end

  test "assigned user can acknowledge reminder" do
    sign_in_with_form(@owner)
    navigate_to_legal_case(@legal_case)

    # Go to reminders tab
    find("[data-testid='legal-case-tab-reminders']").click
    assert_selector "[data-testid='legal-case-reminder-#{@reminder.id}']", wait: 5

    # Click on the reminder to go to Show page
    find("[data-testid='legal-case-reminder-#{@reminder.id}']").click
    assert_selector "[data-testid='case-reminder-btn-acknowledge']", wait: 5

    # Click acknowledge button
    find("[data-testid='case-reminder-btn-acknowledge']").click

    # Wait for flash message and for the acknowledge button to disappear
    # (the button is hidden via v-if when reminder.acknowledged is true)
    assert_selector ".flash-snackbar", wait: 10
    assert_no_selector "[data-testid='case-reminder-btn-acknowledge']", wait: 5

    # Verify acknowledgment in database (now safe since UI confirmed the state change)
    reminder_user = @reminder.case_reminder_users.find_by(user: @owner)
    assert reminder_user.reload.acknowledged?
  end

  private

  def navigate_to_legal_case(legal_case)
    find("[data-testid='nav-hamburger']").click
    assert_selector "[data-testid='nav-drawer']", wait: 5
    within("[data-testid='nav-drawer']") do
      find("[data-testid='nav-item-legal_cases']").click
    end
    assert_selector "[data-testid='legal-cases-btn-new']", wait: 10

    find("[data-testid='legal-cases-btn-view-#{legal_case.id}']").click
    assert_selector "[data-testid='legal-case-tab-info']", wait: 10
  end

  def fill_in_field(selector, with:)
    find(selector).fill_in with: with
  end
end
