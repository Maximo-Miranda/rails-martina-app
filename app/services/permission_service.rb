# frozen_string_literal: true

class PermissionService
  attr_reader :user, :current_project

  def initialize(user, current_project = nil)
    @user = user
    @current_project = current_project
  end

  # Returns a hash of all permissions for the current user
  # This is cached by InertiaRails.once to avoid redundant evaluations
  def all_permissions
    return {} unless user

    {
      # Global permissions (not scoped to a specific project)
      can_manage_users: policy(User).show_menu?,
      can_manage_projects: policy(Project).index?,
      can_create_project: policy(Project).create?,

      # Project-scoped permissions (require current_project)
      can_edit_current_project: project_policy(current_project).update?,
      can_delete_current_project: project_policy(current_project).destroy?,

      # User permissions
      can_update_profile: policy(user).update?,
      can_delete_account: policy(user).destroy?,

      # Navigation permissions
      can_access_dashboard: true,
      can_access_projects: true,
      can_access_users: policy(User).show_menu?,

      # Feature flags (can be extended)
      can_view_analytics: user.global_admin?,
      can_access_admin_panel: user.super_admin?
    }.compact
  end

  # Method to get permissions for a specific project
  def project_permissions(project)
    return {} unless user && project

    {
      can_edit: policy(project).update?,
      can_delete: policy(project).destroy?,
      can_switch: policy(project).switch?
    }.compact
  end

  # Method to get permissions for multiple projects (optimized)
  def projects_permissions(projects)
    return {} unless user && projects

    projects.each_with_object({}) do |project, hash|
      hash[project.id] = project_permissions(project)
    end
  end

  private

  # Helper to get a policy for a given record
  def policy(record)
    return NullPolicy.new(user) if record.nil?
    Pundit.policy!(user, record)
  end

  # Helper specifically for project policies
  def project_policy(record)
    return NullPolicy.new(user) if record.nil?
    Pundit.policy!(user, record)
  end

  # Null object pattern for nil records
  class NullPolicy
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def index? = false
    def show? = false
    def create? = false
    def update? = false
    def destroy? = false
    def show_menu? = false
    def switch? = false
  end
end
