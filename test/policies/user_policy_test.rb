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

  test "super_admin sees all kept users" do
    scope = UserPolicy::Scope.new(@super_admin, User).resolve

    assert_includes scope, @owner
    assert_includes scope, @coworker
    assert_includes scope, @outsider
    assert_includes scope, @super_admin
    refute_includes scope, users(:deleted_user)
  end

  test "admin (global_admin) sees all kept users" do
    scope = UserPolicy::Scope.new(@admin, User).resolve

    assert_includes scope, @owner
    assert_includes scope, @coworker
    assert_includes scope, @outsider
    refute_includes scope, users(:deleted_user)
  end

  test "owner sees only users in their project" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = UserPolicy::Scope.new(@owner, User).resolve

      assert_includes scope, @owner       # owner en test_project
      assert_includes scope, @coworker    # coworker en test_project
      assert_includes scope, @client      # client en test_project
      refute_includes scope, @outsider    # NO tiene rol en test_project
      refute_includes scope, @super_admin # NO tiene rol en test_project
    end
  end

  test "coworker sees only users in their project" do
    ActsAsTenant.with_tenant(@test_project) do
      scope = UserPolicy::Scope.new(@coworker, User).resolve

      assert_includes scope, @owner
      assert_includes scope, @coworker
      assert_includes scope, @client
      refute_includes scope, @outsider
    end
  end

  test "outsider sees only users in their project" do
    ActsAsTenant.with_tenant(@other_project) do
      scope = UserPolicy::Scope.new(@outsider, User).resolve

      assert_includes scope, @owner       # owner también en other_project
      assert_includes scope, @outsider    # owner en other_project
      refute_includes scope, @coworker    # NO tiene rol en other_project
      refute_includes scope, @client      # NO tiene rol en other_project
    end
  end

  test "returns none when no project context" do
    # Usuario sin current_project y sin ActsAsTenant
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
      # Super admin puede ver a cualquiera
      assert UserPolicy.new(@super_admin, @coworker).show?

      # Admin puede ver a cualquiera
      assert UserPolicy.new(@admin, @coworker).show?

      # Owner puede ver usuarios del proyecto
      assert UserPolicy.new(@owner, @coworker).show?

      # Usuario puede verse a sí mismo
      assert UserPolicy.new(@coworker, @coworker).show?

      # Coworker no puede ver a otros (no es owner ni global_admin)
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
    refute UserPolicy.new(@super_admin, @super_admin).destroy?  # No puede borrarse a sí mismo
    refute UserPolicy.new(@admin, @coworker).destroy?           # Admin no puede eliminar
    refute UserPolicy.new(@owner, @coworker).destroy?           # Owner no puede eliminar
  end

  test "remove_from_project? allows global_admin or owner but not self" do
    ActsAsTenant.with_tenant(@test_project) do
      # Super admin puede desvincular
      assert UserPolicy.new(@super_admin, @coworker).remove_from_project?

      # Admin puede desvincular
      assert UserPolicy.new(@admin, @coworker).remove_from_project?

      # Owner puede desvincular
      assert UserPolicy.new(@owner, @coworker).remove_from_project?

      # No puede desvincularse a sí mismo
      refute UserPolicy.new(@owner, @owner).remove_from_project?

      # Coworker no puede desvincular
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
