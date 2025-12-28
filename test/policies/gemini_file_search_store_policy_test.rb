# frozen_string_literal: true

require "test_helper"

class GeminiFileSearchStorePolicyTest < ActiveSupport::TestCase
  def setup
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @test_project = projects(:test_project)
    @global_store = gemini_file_search_stores(:global_store)
    @active_store = gemini_file_search_stores(:active_store)
  end

  # === Scope Tests ===

  test "super_admin sees only global stores" do
    scope = GeminiFileSearchStorePolicy::Scope.new(@super_admin, GeminiFileSearchStore).resolve

    assert_includes scope, @global_store
    assert_not_includes scope, @active_store  # project store not visible
  end

  test "admin sees only global stores" do
    scope = GeminiFileSearchStorePolicy::Scope.new(@admin, GeminiFileSearchStore).resolve

    assert_includes scope, @global_store
    assert_not_includes scope, @active_store
  end

  test "owner sees no global stores" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = GeminiFileSearchStorePolicy::Scope.new(@owner, GeminiFileSearchStore).resolve
      assert_empty scope
    end
  end

  test "coworker sees no global stores" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = GeminiFileSearchStorePolicy::Scope.new(@coworker, GeminiFileSearchStore).resolve
      assert_empty scope
    end
  end

  # === Policy Method Tests ===

  test "index? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, GeminiFileSearchStore).index?
    assert GeminiFileSearchStorePolicy.new(@admin, GeminiFileSearchStore).index?
    refute GeminiFileSearchStorePolicy.new(@owner, GeminiFileSearchStore).index?
    refute GeminiFileSearchStorePolicy.new(@coworker, GeminiFileSearchStore).index?
    refute GeminiFileSearchStorePolicy.new(@client, GeminiFileSearchStore).index?
  end

  test "show? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, @global_store).show?
    assert GeminiFileSearchStorePolicy.new(@admin, @global_store).show?
    refute GeminiFileSearchStorePolicy.new(@owner, @global_store).show?
    refute GeminiFileSearchStorePolicy.new(@coworker, @global_store).show?
    refute GeminiFileSearchStorePolicy.new(@client, @global_store).show?
  end

  test "new? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, GeminiFileSearchStore).new?
    assert GeminiFileSearchStorePolicy.new(@admin, GeminiFileSearchStore).new?
    refute GeminiFileSearchStorePolicy.new(@owner, GeminiFileSearchStore).new?
    refute GeminiFileSearchStorePolicy.new(@coworker, GeminiFileSearchStore).new?
    refute GeminiFileSearchStorePolicy.new(@client, GeminiFileSearchStore).new?
  end

  test "create? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, GeminiFileSearchStore).create?
    assert GeminiFileSearchStorePolicy.new(@admin, GeminiFileSearchStore).create?
    refute GeminiFileSearchStorePolicy.new(@owner, GeminiFileSearchStore).create?
    refute GeminiFileSearchStorePolicy.new(@coworker, GeminiFileSearchStore).create?
    refute GeminiFileSearchStorePolicy.new(@client, GeminiFileSearchStore).create?
  end

  test "edit? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, @global_store).edit?
    assert GeminiFileSearchStorePolicy.new(@admin, @global_store).edit?
    refute GeminiFileSearchStorePolicy.new(@owner, @global_store).edit?
    refute GeminiFileSearchStorePolicy.new(@coworker, @global_store).edit?
    refute GeminiFileSearchStorePolicy.new(@client, @global_store).edit?
  end

  test "update? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, @global_store).update?
    assert GeminiFileSearchStorePolicy.new(@admin, @global_store).update?
    refute GeminiFileSearchStorePolicy.new(@owner, @global_store).update?
    refute GeminiFileSearchStorePolicy.new(@coworker, @global_store).update?
    refute GeminiFileSearchStorePolicy.new(@client, @global_store).update?
  end

  test "destroy? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, @global_store).destroy?
    assert GeminiFileSearchStorePolicy.new(@admin, @global_store).destroy?
    refute GeminiFileSearchStorePolicy.new(@owner, @global_store).destroy?
    refute GeminiFileSearchStorePolicy.new(@coworker, @global_store).destroy?
    refute GeminiFileSearchStorePolicy.new(@client, @global_store).destroy?
  end

  test "show_menu? allows only super_admin and admin" do
    assert GeminiFileSearchStorePolicy.new(@super_admin, GeminiFileSearchStore).show_menu?
    assert GeminiFileSearchStorePolicy.new(@admin, GeminiFileSearchStore).show_menu?
    refute GeminiFileSearchStorePolicy.new(@owner, GeminiFileSearchStore).show_menu?
    refute GeminiFileSearchStorePolicy.new(@coworker, GeminiFileSearchStore).show_menu?
  end
end
