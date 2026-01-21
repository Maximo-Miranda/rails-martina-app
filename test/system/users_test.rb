# frozen_string_literal: true

require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
  end

  test "super_admin can see users menu in navigation" do
    sign_in_with_form(@super_admin)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-users']"
    end
  end

  test "admin can see users menu in navigation" do
    sign_in_with_form(@admin)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-users']"
    end
  end

  test "owner can see users menu in navigation" do
    sign_in_with_form(@owner)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-users']"
    end
  end

  test "coworker cannot see users menu in navigation" do
    sign_in_with_form(@coworker)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-users']"
    end
  end

  test "client cannot see users menu in navigation" do
    sign_in_with_form(@client)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-users']"
    end
  end

  test "super_admin can access users list directly" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_selector "[data-testid='users-table']"
  end

  test "owner can access users list directly" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-table']"
  end

  test "coworker is redirected when trying to access users directly" do
    sign_in_with_form(@coworker)

    visit users_path
    assert_no_selector "[data-testid='users-table']"
  end

  test "super_admin can see invite button" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_selector "[data-testid='users-btn-invite']"
  end

  test "owner can see invite button" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-btn-invite']"
  end

  test "admin can see invite button" do
    sign_in_with_form(@admin)

    visit users_path
    assert_selector "[data-testid='users-btn-invite']"
  end

  test "users list shows only users from current project" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-table']"

    assert_text @coworker.full_name
    assert_text @client.full_name

    outsider = users(:outsider_user)
    assert_no_text outsider.full_name
  end

  test "owner can see unlink button for users in project" do
    sign_in_with_form(@owner)

    visit users_path
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "admin can see unlink button for users in project" do
    sign_in_with_form(@admin)

    visit users_path
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "owner can unlink a user from the project" do
    sign_in_with_form(@owner)

    visit users_path
    assert_text @coworker.full_name

    find("[data-testid='users-row-#{@coworker.id}-btn-unlink']").click

    assert_selector "[data-testid='users-dialog-unlink-btn-confirm']"
    find("[data-testid='users-dialog-unlink-btn-confirm']").click

    assert_no_text @coworker.full_name
  end

  test "super_admin can see delete button for users" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-delete']"
  end

  test "owner cannot see delete button (only unlink)" do
    sign_in_with_form(@owner)

    visit users_path

    assert_no_selector "[data-testid='users-row-#{@coworker.id}-btn-delete']"
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "admin cannot see delete button (only unlink)" do
    sign_in_with_form(@admin)

    visit users_path

    assert_no_selector "[data-testid='users-row-#{@coworker.id}-btn-delete']"
    assert_selector "[data-testid='users-row-#{@coworker.id}-btn-unlink']"
  end

  test "super_admin can delete a user" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_text @coworker.full_name

    find("[data-testid='users-row-#{@coworker.id}-btn-delete']").click

    assert_selector "[data-testid='users-dialog-delete-btn-confirm']"
    find("[data-testid='users-dialog-delete-btn-confirm']").click

    assert_no_text @coworker.full_name
  end

  test "owner can view user details" do
    sign_in_with_form(@owner)

    visit users_path
    find("[data-testid='users-row-#{@coworker.id}-btn-view']").click

    assert_current_path user_path(@coworker)
    assert_text @coworker.full_name
    assert_text @coworker.email
  end

  test "owner can navigate to invite form" do
    sign_in_with_form(@owner)

    visit users_path
    find("[data-testid='users-btn-invite']").click

    assert_current_path new_invitation_users_path
    assert_selector "[data-testid='users-input-email']"
  end

  test "owner can send invitation to new user" do
    sign_in_with_form(@owner)

    visit new_invitation_users_path

    fill_in_field "[data-testid='users-input-email'] input", with: "newuser@example.com"

    find("[data-testid='users-select-role']").click
    find(".v-list-item", text: t("roles.coworker")).click

    find("[data-testid='users-invite-form-btn-submit']").click

    assert_current_path users_path
    assert_text "newuser@example.com"
  end

  test "owner cannot unlink themselves from project" do
    sign_in_with_form(@owner)

    visit users_path
    assert_no_selector "[data-testid='users-row-#{@owner.id}-btn-unlink']"
  end

  test "super_admin cannot delete themselves" do
    sign_in_with_form(@super_admin)

    visit users_path
    assert_no_selector "[data-testid='users-row-#{@super_admin.id}-btn-delete']"
  end

  test "global admin without current_project is auto-assigned to existing project" do
    @super_admin.update_column(:current_project_id, nil)

    sign_in_with_form(@super_admin)

    assert_no_current_path new_project_path
    assert_selector "[data-testid='nav-drawer']"

    @super_admin.reload
    assert_not_nil @super_admin.current_project_id
  end

  private

  def t(key, **options)
    I18n.t(key, scope: :frontend, **options)
  end
end
