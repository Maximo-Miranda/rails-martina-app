# frozen_string_literal: true

require "test_helper"

class GeminiFileSearchStoreTest < ActiveSupport::TestCase
  def setup
    @active_store = gemini_file_search_stores(:active_store)
    @pending_store = gemini_file_search_stores(:pending_store)
    @failed_store = gemini_file_search_stores(:failed_store)
    @global_store = gemini_file_search_stores(:global_store)
    @deleted_store = gemini_file_search_stores(:deleted_store)
    @test_project = projects(:test_project)
  end

  # === Validations ===

  test "requires display_name" do
    store = GeminiFileSearchStore.new(display_name: nil)
    assert_not store.valid?
    assert store.errors[:display_name].present?
  end

  test "gemini_store_name must be unique when present" do
    duplicate = GeminiFileSearchStore.new(
      display_name: "Duplicate Store",
      gemini_store_name: @active_store.gemini_store_name
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:gemini_store_name].present?
  end

  test "allows multiple nil gemini_store_name" do
    store1 = GeminiFileSearchStore.create!(display_name: "Store 1", status: :pending)
    store2 = GeminiFileSearchStore.new(display_name: "Store 2", status: :pending)
    assert store2.valid?
    store1.destroy
  end

  # === Enums ===

  test "status enum has correct values" do
    assert_equal "pending", @pending_store.status
    assert_equal "active", @active_store.status
    assert_equal "failed", @failed_store.status
    assert_equal "deleted", @deleted_store.status
  end

  test "default status is pending" do
    store = GeminiFileSearchStore.new(display_name: "New Store")
    assert_equal "pending", store.status
  end

  # === Scopes ===

  test "global scope returns only stores without project" do
    global_stores = GeminiFileSearchStore.global
    assert_includes global_stores, @global_store
    assert_not_includes global_stores, @active_store
  end

  test "for_project scope returns stores for specific project" do
    project_stores = GeminiFileSearchStore.for_project(@test_project)
    assert_includes project_stores, @active_store
    assert_not_includes project_stores, @global_store
    # Pending store belongs to another project now due to 1-to-1 constraint
    assert_not_includes project_stores, @pending_store
  end

  # === Helper Methods ===

  test "global? returns true for stores without project" do
    assert @global_store.global?
    assert_not @active_store.global?
  end

  test "synced? returns true only when active with gemini_store_name" do
    assert @active_store.synced?
    assert_not @pending_store.synced?
    assert_not @failed_store.synced?
  end

  # === Discard (Soft Delete) ===

  test "soft deletes store using discard" do
    store = GeminiFileSearchStore.create!(display_name: "To Delete", status: :active)
    assert_not store.discarded?

    store.discard!
    assert store.discarded?
    assert_not_nil store.deleted_at
    store.destroy
  end

  test "default scope excludes discarded stores" do
    assert_not_includes GeminiFileSearchStore.kept, @deleted_store
    assert_includes GeminiFileSearchStore.with_discarded, @deleted_store
  end

  # === Multi-tenancy ===

  test "allows store without project (global store)" do
    store = GeminiFileSearchStore.new(display_name: "Global", project: nil)
    assert store.valid?
  end

  test "allows store with project" do
    project = projects(:other_project)
    store = GeminiFileSearchStore.new(display_name: "Project Store", project: project)
    assert store.valid?
  end
end
