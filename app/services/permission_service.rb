# frozen_string_literal: true

class PermissionService
  attr_reader :user, :current_project

  def initialize(user, current_project = nil)
    @user = user
    @current_project = current_project
  end

  def all_permissions
    return {} unless user

    {
      # Global permissions (not scoped to a specific project)
      can_manage_users: policy(User).show_menu?,
      can_invite_users: policy(User).invite?,
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
      can_access_gemini_stores: gemini_store_policy.show_menu?,

      # Feature flags (can be extended)
      can_view_analytics: user.global_admin?,
      can_access_admin_panel: user.super_admin?,
    }.compact
  end

  def project_permissions(project)
    return {} unless user && project

    {
      can_edit: policy(project).update?,
      can_delete: policy(project).destroy?,
      can_switch: policy(project).switch?,
    }.compact
  end

  def projects_permissions(projects)
    return {} unless user && projects

    projects.each_with_object({}) do |project, hash|
      hash[project.id] = project_permissions(project)
    end
  end

  def user_permissions(target_user)
    return {} unless user && target_user

    {
      can_view: policy(target_user).show?,
      can_edit: policy(target_user).update?,
      can_delete: policy(target_user).destroy?,
      can_remove_from_project: policy(target_user).remove_from_project?,
    }.compact
  end

  def users_permissions(users)
    return {} unless user && users

    users.each_with_object({}) do |target_user, hash|
      hash[target_user.id] = user_permissions(target_user)
    end
  end

  private

  def policy(record)
    return NullPolicy.new(user) if record.nil?
    Pundit.policy!(user, record)
  end

  def project_policy(record)
    return NullPolicy.new(user) if record.nil?
    Pundit.policy!(user, record)
  end

  def gemini_store_policy
    Pundit.policy!(user, GeminiFileSearchStore)
  end

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
