# frozen_string_literal: true

require "application_system_test_case"

class DashboardAccessTest < ApplicationSystemTestCase
  setup do
    @user = users(:confirmed_user)
  end

  test "can sign in directly and access dashboard" do
    sign_in_with_form(@user)
    visit dashboard_path

    assert_current_path dashboard_path

    first_name = @user.full_name.split.first
    assert_text "¡Hola, #{first_name}!"
  end

  test "can sign out and is redirected to login" do
    sign_in_with_form(@user)

    visit dashboard_path

    assert_current_path dashboard_path

    sign_out_with_ui

    visit dashboard_path

    assert_current_path new_user_session_path
  end
end
