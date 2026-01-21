# frozen_string_literal: true

require "application_system_test_case"

class GeminiFileSearchStoresTest < ApplicationSystemTestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @global_store = gemini_file_search_stores(:global_store)
    @test_project = projects(:test_project)
  end

  test "super_admin can see gemini stores menu in navigation" do
    sign_in_with_form(@super_admin)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-gemini_file_search_stores']"
    end
  end

  test "admin can see gemini stores menu in navigation" do
    sign_in_with_form(@admin)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_selector "[data-testid='nav-item-gemini_file_search_stores']"
    end
  end

  test "owner cannot see gemini stores menu in navigation" do
    sign_in_with_form(@owner)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-gemini_file_search_stores']"
    end
  end

  test "coworker cannot see gemini stores menu in navigation" do
    sign_in_with_form(@coworker)

    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click

    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-gemini_file_search_stores']"
    end
  end

  test "super_admin can access gemini stores list directly" do
    sign_in_with_form(@super_admin)

    visit gemini_file_search_stores_path
    assert_selector "[data-testid='gemini-stores-table']"
  end

  test "admin can access gemini stores list directly" do
    sign_in_with_form(@admin)

    visit gemini_file_search_stores_path
    assert_selector "[data-testid='gemini-stores-table']"
  end

  test "owner is redirected when trying to access gemini stores directly" do
    sign_in_with_form(@owner)

    visit gemini_file_search_stores_path

    assert_no_selector "[data-testid='gemini-stores-table']"
  end

  test "stores list shows only global stores" do
    sign_in_with_form(@super_admin)

    visit gemini_file_search_stores_path
    assert_selector "[data-testid='gemini-stores-table']"

    assert_text @global_store.display_name
    active_store = gemini_file_search_stores(:active_store)
    assert_no_text active_store.display_name
  end

  test "super_admin can see create button" do
    sign_in_with_form(@super_admin)

    visit gemini_file_search_stores_path
    assert_selector "[data-testid='gemini-stores-btn-create']"
  end

  test "admin can see create button" do
    sign_in_with_form(@admin)

    visit gemini_file_search_stores_path
    assert_selector "[data-testid='gemini-stores-btn-create']"
  end

  test "super_admin can create a new global store" do
    with_vcr_cassette("system/store_create") do
      sign_in_with_form(@super_admin)

      visit gemini_file_search_stores_path
      find("[data-testid='gemini-stores-btn-create']").click

      assert_selector "[data-testid='gemini-store-form']"
      fill_in_field "[data-testid='gemini-store-input-display-name'] input", with: "New Global Store"

      find("[data-testid='gemini-store-form-btn-submit']").click

      assert_selector "[data-testid='gemini-stores-table']"
      assert_text "New Global Store"
    end
  end

  test "super_admin can view store details" do
    sign_in_with_form(@super_admin)

    visit gemini_file_search_stores_path
    find("[data-testid='gemini-store-btn-show-#{@global_store.id}']").click

    assert_selector "[data-testid='gemini-store-detail']"
    assert_text @global_store.display_name
    assert_text @global_store.gemini_store_name
  end

  test "super_admin can delete a store" do
    with_vcr_lifecycle_cassette("system/store_delete_ui_lifecycle") do
      sign_in_with_form(@super_admin)

      ActiveJob::Base.queue_adapter = :inline

      begin
        temp_store = GeminiFileSearchStore.create!(
          display_name: "Store to Delete",
          status: :pending,
          project_id: nil
        )
        Gemini::CreateStoreJob.perform_now(temp_store.id)
        temp_store.reload

        visit gemini_file_search_stores_path
        assert_text temp_store.display_name

        find("[data-testid='gemini-store-btn-delete-#{temp_store.id}']").click

        assert_selector "[data-testid='gemini-stores-delete-dialog']", visible: true, wait: 10
        find("[data-testid='gemini-stores-delete-dialog-btn-confirm']", visible: true, wait: 10).click

        assert_no_text temp_store.display_name, wait: 10
      ensure
        ActiveJob::Base.queue_adapter = :test
      end
    end
  end

  test "super_admin can search stores" do
    sign_in_with_form(@super_admin)

    store1 = GeminiFileSearchStore.create!(display_name: "Alpha Store", status: :active)
    store2 = GeminiFileSearchStore.create!(display_name: "Beta Store", status: :active)

    visit gemini_file_search_stores_path

    assert_text store1.display_name
    assert_text store2.display_name

    fill_in_field "[data-testid='gemini-stores-input-search'] input", with: "Alpha"

    assert_text store1.display_name, wait: 2
    assert_no_text store2.display_name, wait: 2

    store1.destroy
    store2.destroy
  end
end
