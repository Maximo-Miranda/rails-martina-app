# frozen_string_literal: true

require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  setup do
    @user = users(:confirmed_user)
  end

  test "displays login page correctly and navigation elements" do
    visit new_user_session_path

    assert_selector '[data-testid="login-card"]'
    assert_selector '[data-testid="login-title"]'
    assert_selector '[data-testid="input-email"]'
    assert_selector '[data-testid="input-password"]'
    assert_selector '[data-testid="btn-submit"]'

    assert_selector '[data-testid="auth-app-bar"]'
    assert_selector '[data-testid="auth-logo"]'
    assert_selector '[data-testid="link-forgot-password"]'
    assert_selector '[data-testid="link-register"]'
  end

  test "successful login redirects to dashboard" do
    visit new_user_session_path

    find('[data-testid="input-email"]').fill_in with: @user.email
    find('[data-testid="input-password"]').fill_in with: "password123"
    find('[data-testid="btn-submit"]').click

    assert_current_path dashboard_path
  end

  test "failed login with wrong password stays on login page" do
    visit new_user_session_path

    find('[data-testid="input-email"]').fill_in with: @user.email
    find('[data-testid="input-password"]').fill_in with: "wrongpassword"
    find('[data-testid="btn-submit"]').click

    assert_selector '[data-testid="login-card"]'
    assert_selector '[data-testid="flash-alert"]', text: I18n.t("users.sessions.create.invalid_credentials")
  end

  test "failed login with non-existent email stays on login page" do
    visit new_user_session_path

    find('[data-testid="input-email"]').fill_in with: "nonexistent@example.com"
    find('[data-testid="input-password"]').fill_in with: "password123"
    find('[data-testid="btn-submit"]').click

    assert_selector '[data-testid="login-card"]'
    assert_selector '[data-testid="flash-alert"]', text: I18n.t("users.sessions.create.invalid_credentials")
  end

  test "forgot password link navigates to password reset page" do
    visit new_user_session_path

    find('[data-testid="link-forgot-password"]').click

    assert_current_path new_user_password_path
  end

  test "register link navigates to registration page" do
    visit new_user_session_path

    find('[data-testid="link-register"]').click

    assert_current_path new_user_registration_path
  end

  test "logo link navigates to home" do
    visit new_user_session_path

    find('[data-testid="auth-logo"]').click

    assert_current_path root_path
  end

  test "remember me checkbox is visible and clickable" do
    visit new_user_session_path

    checkbox = find('[data-testid="checkbox-remember"]')
    assert checkbox
  end
end
