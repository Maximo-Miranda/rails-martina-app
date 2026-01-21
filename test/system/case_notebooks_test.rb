# frozen_string_literal: true

require "application_system_test_case"

class CaseNotebooksTest < ApplicationSystemTestCase
  setup do
    @owner = users(:confirmed_user)
    @project = projects(:test_project)
    @legal_case = legal_cases(:legal_case_one)
    @notebook = case_notebooks(:principal_notebook)
  end

  test "owner can create case notebook" do
    sign_in_with_form(@owner)
    navigate_to_legal_case(@legal_case)

    find("[data-testid='legal-case-tab-notebooks']").click
    assert_selector "[data-testid='legal-case-btn-add-notebook']", wait: 5

    find("[data-testid='legal-case-btn-add-notebook']").click
    assert_selector "[data-testid='case-notebooks-input-type']", wait: 5

    find("[data-testid='case-notebooks-input-type']").click
    find(".v-list-item", text: /Incidentes/i).click

    fill_in_field "[data-testid='case-notebooks-input-code'] input", with: "C99"
    fill_in_field "[data-testid='case-notebooks-input-description'] textarea", with: "Cuaderno de prueba"
    fill_in_field "[data-testid='case-notebooks-input-volume'] input", with: "1"

    find("[data-testid='case-notebooks-btn-submit']").click

    assert_selector ".flash-snackbar", wait: 10
    assert_text "C99", wait: 10

    notebook = @legal_case.case_notebooks.find_by(code: "C99")
    assert_not_nil notebook
    assert_equal "incidentes", notebook.notebook_type
  end

  test "owner can delete case notebook" do
    sign_in_with_form(@owner)
    navigate_to_legal_case(@legal_case)

    find("[data-testid='legal-case-tab-notebooks']").click
    assert_selector "[data-testid='legal-case-notebook-#{@notebook.id}']", wait: 5

    notebook_id = @notebook.id
    find("[data-testid='legal-case-notebook-btn-delete-#{notebook_id}']").click

    assert_selector ".v-dialog", wait: 5
    find(".v-dialog .v-btn", text: /Eliminar|Delete|Sí/i).click

    assert_selector ".flash-snackbar", wait: 10
    assert_no_selector "[data-testid='legal-case-notebook-#{notebook_id}']", wait: 10
    assert @notebook.reload.discarded?
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
