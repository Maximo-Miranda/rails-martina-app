# frozen_string_literal: true

require "application_system_test_case"

class LegalCasesTest < ApplicationSystemTestCase
  setup do
    @owner = users(:confirmed_user)
    @project = projects(:test_project)
    @legal_case = legal_cases(:legal_case_one)
  end

  test "owner can create legal case" do
    sign_in_with_form(@owner)
    navigate_to_legal_cases

    find("[data-testid='legal-cases-btn-new']").click
    assert_selector "[data-testid='legal-case-input-case-number']", wait: 10

    fill_in_field "[data-testid='legal-case-input-case-number'] input", with: "2025-TEST-001"
    fill_in_field "[data-testid='legal-case-input-court'] input", with: "Juzgado 1 Civil Test"

    find("[data-testid='legal-case-select-specialty']").click
    find(".v-list-item", text: "Civil").click

    fill_in_field "[data-testid='legal-case-input-action-type'] input", with: "Proceso Ordinario"
    fill_in_field "[data-testid='legal-case-input-filing-date'] input", with: Date.current.strftime("%Y-%m-%d")
    fill_in_field "[data-testid='legal-case-input-plaintiff'] input", with: "Demandante Test"
    fill_in_field "[data-testid='legal-case-input-defendant'] input", with: "Demandado Test"
    fill_in_field "[data-testid='legal-case-input-lawyer-in-charge'] input", with: "Abogado Test"
    fill_in_field "[data-testid='legal-case-input-lawyer-professional-card'] input", with: "TP-99999"
    fill_in_field "[data-testid='legal-case-input-lawyer-phone'] input", with: "3001234567"
    fill_in_field "[data-testid='legal-case-input-lawyer-email'] input", with: "test@example.com"

    find("[data-testid='legal-case-form-btn-submit']").click

    assert_selector ".flash-snackbar", wait: 10
    assert_text "2025-TEST-001", wait: 10

    legal_case = LegalCase.find_by(case_number: "2025-TEST-001")
    assert_not_nil legal_case
    assert_equal 1, legal_case.case_notebooks.count
    assert_equal "principal", legal_case.case_notebooks.first.notebook_type
  end

  test "owner can delete legal case" do
    sign_in_with_form(@owner)
    navigate_to_legal_cases

    case_id = @legal_case.id
    find("[data-testid='legal-cases-btn-delete-#{case_id}']").click

    assert_selector ".v-dialog", wait: 5
    find(".v-dialog .v-btn", text: /Eliminar|Delete|Sí/i).click

    assert_selector ".flash-snackbar", wait: 10
    assert_no_selector "[data-testid='legal-cases-btn-delete-#{case_id}']", wait: 10
    assert @legal_case.reload.discarded?
  end

  private

  def navigate_to_legal_cases
    find("[data-testid='nav-hamburger']").click
    assert_selector "[data-testid='nav-drawer']", wait: 5
    within("[data-testid='nav-drawer']") do
      find("[data-testid='nav-item-legal_cases']").click
    end
    assert_selector "[data-testid='legal-cases-btn-new']", wait: 10
  end

  def fill_in_field(selector, with:)
    find(selector).fill_in with: with
  end
end
