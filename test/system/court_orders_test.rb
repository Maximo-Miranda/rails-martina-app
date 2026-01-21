# frozen_string_literal: true

require "application_system_test_case"

class CourtOrdersTest < ApplicationSystemTestCase
  setup do
    @owner = users(:confirmed_user)
    @project = projects(:test_project)
    @legal_case = legal_cases(:legal_case_one)
  end

  test "owner can create court order" do
    sign_in_with_form(@owner)
    navigate_to_legal_case(@legal_case)

    # Go to orders tab
    find("[data-testid='legal-case-tab-orders']").click
    assert_selector "[data-testid='legal-case-btn-add-order']", wait: 5

    find("[data-testid='legal-case-btn-add-order']").click
    # Navigates to CourtOrders/Form.vue which uses "court-orders-*" selectors
    assert_selector "[data-testid='court-orders-input-type']", wait: 5

    # Fill form - wait for menu to open then select
    find("[data-testid='court-orders-input-type']").click
    assert_selector ".v-overlay--active .v-list-item", wait: 5
    find(".v-overlay--active .v-list-item", text: /Auto Interlocutorio/i).click

    # Wait for menu to close before filling other fields
    assert_no_selector ".v-overlay--active .v-list", wait: 5

    fill_in_field "[data-testid='court-orders-input-summary'] textarea", with: "Auto de prueba para test"
    fill_in_field "[data-testid='court-orders-input-date'] input", with: Date.current.strftime("%Y-%m-%d")
    fill_in_field "[data-testid='court-orders-input-deadline'] input", with: 10.days.from_now.to_date.strftime("%Y-%m-%d")

    # Wait for submit button to be ready and click
    assert_selector "[data-testid='court-orders-btn-submit']:not([disabled])", wait: 5
    find("[data-testid='court-orders-btn-submit']").click

    # Wait for redirect and success flash - confirms DB transaction completed
    assert_current_path(/\/legal_cases\/#{@legal_case.id}/, wait: 15)
    assert_selector ".flash-snackbar", wait: 10

    # Verify creation in database
    order = @legal_case.court_orders.reload.find_by(summary: "Auto de prueba para test")
    assert_not_nil order, "Court order should have been created"
    assert_equal "auto_interlocutorio", order.order_type
    assert_equal "pendiente", order.status
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
