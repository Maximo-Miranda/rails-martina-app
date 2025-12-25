# frozen_string_literal: true

require "test_helper"

class PermissionServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:confirmed_user)
    @project = projects(:test_project)
    # Clear any existing roles for clean state
    @user.roles.destroy_all
    @user.reload
  end

  test "returns empty hash when user is nil" do
    service = PermissionService.new(nil, @project)
    assert_equal({}, service.all_permissions)
  end

  test "includes can_manage_users for global admins" do
    @user.add_role(:super_admin)
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_manage_users]
  end

  test "includes can_manage_users for project owners" do
    @user.add_role(:owner, @project)
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_manage_users]
  end

  test "excludes can_manage_users for regular users" do
    @user.add_role(:coworker, @project)
    service = PermissionService.new(@user, @project)

    refute service.all_permissions[:can_manage_users]
  end

  test "includes can_edit_current_project for project owners" do
    @user.add_role(:owner, @project)
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_edit_current_project]
  end

  test "excludes can_edit_current_project for clients" do
    @user.add_role(:client, @project)
    service = PermissionService.new(@user, @project)

    # Client should NOT be able to edit project
    # (only global_admin or owner can edit)
    refute service.all_permissions[:can_edit_current_project]
  end

  test "includes can_delete_current_project for project owners" do
    @user.add_role(:owner, @project)
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_delete_current_project]
  end

  test "excludes can_delete_current_project for clients" do
    @user.add_role(:client, @project)
    service = PermissionService.new(@user, @project)

    # Client should NOT be able to delete project
    # (only global_admin or owner can delete)
    refute service.all_permissions[:can_delete_current_project]
  end

  test "includes can_access_admin_panel for super_admins" do
    @user.add_role(:super_admin)
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_access_admin_panel]
  end

  test "excludes can_access_admin_panel for regular admins" do
    @user.add_role(:admin)
    service = PermissionService.new(@user, @project)

    refute service.all_permissions[:can_access_admin_panel]
  end

  test "handles nil current_project gracefully" do
    @user.add_role(:super_admin)
    service = PermissionService.new(@user, nil)

    # Project-scoped permissions should be false or nil
    refute service.all_permissions[:can_edit_current_project]
    refute service.all_permissions[:can_delete_current_project]
  end

  test "includes can_update_profile for current user" do
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_update_profile]
  end

  test "project_permissions returns correct permissions for project owner" do
    @user.add_role(:owner, @project)
    service = PermissionService.new(@user, @project)

    perms = service.project_permissions(@project)

    assert perms[:can_edit]
    assert perms[:can_delete]
    assert perms[:can_switch]
  end

  test "project_permissions returns correct permissions for project client" do
    @user.add_role(:client, @project)
    service = PermissionService.new(@user, @project)

    perms = service.project_permissions(@project)

    # Client cannot edit or delete project
    refute perms[:can_edit]
    refute perms[:can_delete]
    # But can switch to it
    assert perms[:can_switch]
  end

  test "projects_permissions returns permissions for multiple projects" do
    project2 = projects(:other_project)
    @user.add_role(:owner, @project)
    @user.add_role(:coworker, project2)

    service = PermissionService.new(@user, @project)
    perms = service.projects_permissions([ @project, project2 ])

    # Owner of test_project should have edit and delete permissions
    assert perms[@project.id][:can_edit]
    assert perms[@project.id][:can_delete]
    assert perms[@project.id][:can_switch]

    # Coworker of other_project should NOT have edit and delete permissions
    refute perms[project2.id][:can_edit]
    refute perms[project2.id][:can_delete]
    # But should be able to switch
    assert perms[project2.id][:can_switch]
  end

  test "projects_permissions returns empty hash when user is nil" do
    service = PermissionService.new(nil, @project)

    assert_equal({}, service.projects_permissions([ @project ]))
  end

  test "projects_permissions returns empty hash when projects is empty" do
    service = PermissionService.new(@user, @project)

    assert_equal({}, service.projects_permissions([]))
  end

  test "includes can_view_analytics for global admins" do
    @user.add_role(:admin)
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_view_analytics]
  end

  test "excludes can_view_analytics for regular users" do
    @user.add_role(:coworker, @project)
    service = PermissionService.new(@user, @project)

    refute service.all_permissions[:can_view_analytics]
  end

  test "includes can_create_project for all users" do
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_create_project]
  end

  test "includes can_access_dashboard for all users" do
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_access_dashboard]
  end

  test "includes can_access_projects for all users" do
    service = PermissionService.new(@user, @project)

    assert service.all_permissions[:can_access_projects]
  end
end
