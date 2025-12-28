# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  def setup
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)
    @test_project = projects(:test_project)
    @other_project = projects(:other_project)
  end

  # === Scope Tests ===

  test "super_admin sees only users in their project" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = UserPolicy::Scope.new(@super_admin, User).resolve

      assert_includes scope, @owner       # owner returned in active record collection (scope) for project test_project
      assert_includes scope, @coworker    # coworker returned in active record collection (scope) for project test_project
      assert_includes scope, @client      # client returned in active record collection (scope) for project test_project
      assert_includes scope, @super_admin # super_admin returned in active record collection (scope) for project test_project
      assert_includes scope, @admin       # admin returned in active record collection (scope) for project test_project
      refute_includes scope, @outsider    # Not included since no role in test_project
      refute_includes scope, users(:deleted_user)
    end
  end

  test "admin (global_admin) sees only users in their project" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = UserPolicy::Scope.new(@admin, User).resolve

      assert_includes scope, @owner       # owner returned in active record collection (scope) for project test_project
      assert_includes scope, @coworker    # coworker returned in active record collection (scope) for project test_project
      assert_includes scope, @client      # client returned in active record collection (scope) for project test_project
      assert_includes scope, @super_admin # super_admin returned in active record collection (scope) for project test_project
      assert_includes scope, @admin       # admin returned in active record collection (scope) for project test_project
      refute_includes scope, @outsider    # Not included since no role in test_project
      refute_includes scope, users(:deleted_user)
    end
  end

  test "owner sees only users in their project" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = UserPolicy::Scope.new(@owner, User).resolve

      assert_includes scope, @owner       # owner returned in active record collection (scope) for project test_project
      assert_includes scope, @coworker    # coworker returned in active record collection (scope) for project test_project
      assert_includes scope, @client      # client returned in active record collection (scope) for project test_project
      assert_includes scope, @super_admin # super_admin returned in active record collection (scope) for project test_project
      assert_includes scope, @admin       # admin returned in active record collection (scope) for project test_project
      refute_includes scope, @outsider    # Not included since no role in test_project
    end
  end

  test "coworker sees only users in their project" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = UserPolicy::Scope.new(@coworker, User).resolve

      assert_includes scope, @owner       # owner returned in active record collection (scope) for project test_project
      assert_includes scope, @coworker    # coworker returned in active record collection (scope) for project test_project
      assert_includes scope, @client      # client returned in active record collection (scope) for project test_project
      refute_includes scope, @outsider    # Not included since no role in test_project
    end
  end

  test "outsider sees only users in their project" do
    ActsAsTenant.with_tenant(@other_project) do
      scope = UserPolicy::Scope.new(@outsider, User).resolve

      assert_includes scope, @owner       # owner returned in active record collection (scope) for project other_project
      assert_includes scope, @outsider    # outsider returned in active record collection (scope) for project other_project
      refute_includes scope, @coworker    # Not included since no role in other_project
      refute_includes scope, @client      # Not included since no role in other_project
    end
  end

  test "returns none when no project context" do
    user_without_project = User.new(full_name: "No project", email: "noproj@test.com")

    ActsAsTenant.without_tenant do
      scope = UserPolicy::Scope.new(user_without_project, User).resolve
      assert_empty scope
    end
  end

  # === Policy Method Tests ===

  test "index? allows global_admin or owner" do
    ActsAsTenant.with_tenant(@test_project) do
      assert UserPolicy.new(@super_admin, User).index?
      assert UserPolicy.new(@admin, User).index?
      assert UserPolicy.new(@owner, User).index?
      refute UserPolicy.new(@coworker, User).index?
      refute UserPolicy.new(@client, User).index?
    end
  end

  test "show? allows global_admin, owner, or self" do
    ActsAsTenant.with_tenant(@test_project) do
      # Super admin can view anyone
      assert UserPolicy.new(@super_admin, @coworker).show?

      # Admin can view anyone
      assert UserPolicy.new(@admin, @coworker).show?

      # Owner can view users in the project
      assert UserPolicy.new(@owner, @coworker).show?

      # User can view yourself
      assert UserPolicy.new(@coworker, @coworker).show?

      # Coworker cannot view others (not owner or global_admin)
      refute UserPolicy.new(@coworker, @client).show?
    end
  end

  test "invite? allows global_admin or owner" do
    ActsAsTenant.with_tenant(@test_project) do
      assert UserPolicy.new(@super_admin, User).invite?
      assert UserPolicy.new(@admin, User).invite?
      assert UserPolicy.new(@owner, User).invite?
      refute UserPolicy.new(@coworker, User).invite?
    end
  end

  test "destroy? only allows super_admin and not self" do
    assert UserPolicy.new(@super_admin, @coworker).destroy?
    refute UserPolicy.new(@super_admin, @super_admin).destroy?  # Cannot delete self
    refute UserPolicy.new(@admin, @coworker).destroy?           # Admin cannot delete
    refute UserPolicy.new(@owner, @coworker).destroy?           # Owner cannot delete
  end

  test "remove_from_project? allows global_admin or owner but not self" do
    ActsAsTenant.with_tenant(@test_project) do
      # Super admin can remove from project
      assert UserPolicy.new(@super_admin, @coworker).remove_from_project?

      # Admin can remove from project
      assert UserPolicy.new(@admin, @coworker).remove_from_project?

      # Owner can remove from project
      assert UserPolicy.new(@owner, @coworker).remove_from_project?

      # Cannot remove themselves
      refute UserPolicy.new(@owner, @owner).remove_from_project?

      # Coworker cannot remove from project
      refute UserPolicy.new(@coworker, @client).remove_from_project?
    end
  end

  test "show_menu? allows global_admin or owner" do
    ActsAsTenant.with_tenant(@test_project) do
      assert UserPolicy.new(@super_admin, User).show_menu?
      assert UserPolicy.new(@admin, User).show_menu?
      assert UserPolicy.new(@owner, User).show_menu?
      refute UserPolicy.new(@coworker, User).show_menu?
    end
  end
end
