# frozen_string_literal: true

module SystemTestHelper
  def sign_in_with_form(user, password: "password123")
    visit new_user_session_path
    assert_selector "[data-testid='login-card']"

    fill_in_field "[data-testid='input-email'] input", with: user.email
    fill_in_field "[data-testid='input-password'] input", with: password
    find("[data-testid='btn-submit']").click

    assert_no_current_path new_user_session_path
  end

  def sign_out_with_ui
    page.execute_script("window.scrollTo(0, 0)")
    find("[data-testid='user-menu-button']").click
    assert_selector "[data-testid='user-menu']", wait: 5
    find("[data-testid='btn-logout']").click
    assert_no_current_path dashboard_path
  end

  private

  def fill_in_field(selector, with:)
    find(selector).fill_in with: with
  end
end
