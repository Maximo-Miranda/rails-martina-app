# frozen_string_literal: true

class DocumentPolicy < ApplicationPolicy
  def index?
    if global_context?
      admin_access?
    else
      user_has_project_access?
    end
  end

  def show?
    index?
  end

  def new?
    create?
  end

  def create?
    if global_context?
      admin_access?
    else
      user_can_edit_project?
    end
  end

  def destroy?
    create?
  end

  def self.show_menu?(user)
    user&.has_any_role?(:super_admin, :admin)
  end

  def self.show_project_menu?(user, project)
    return false unless user && project
    return true if user.has_any_role?(:super_admin, :admin)

    user.has_role?(:owner, project) ||
      user.has_role?(:coworker, project) ||
      user.has_role?(:client, project)
  end

  class Scope < ApplicationPolicy::Scope
    # acts_as_tenant handles project filtering; this is a defensive fallback.
    def resolve
      if user.has_any_role?(:super_admin, :admin)
        scope.all
      else
        scope.where(project_id: user.accessible_projects.select(:id))
      end
    end
  end

  private

  def global_context?
    record.is_a?(Document) && record.project_id.nil?
  end

  def admin_access?
    user.has_any_role?(:super_admin, :admin)
  end

  def user_has_project_access?
    return true if admin_access?
    return false unless record_has_project?

    user.has_role?(:owner, record.project) ||
      user.has_role?(:coworker, record.project) ||
      user.has_role?(:client, record.project)
  end

  def user_can_edit_project?
    return true if admin_access?
    return false unless record_has_project?

    user.has_role?(:owner, record.project) ||
      user.has_role?(:coworker, record.project)
  end

  def record_has_project?
    !record.is_a?(Class) && record.project.present?
  end
end
