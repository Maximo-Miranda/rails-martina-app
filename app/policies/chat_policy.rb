# frozen_string_literal: true

class ChatPolicy < ApplicationPolicy
  def self.show_menu?(user, project)
    return false unless user && project

    return true if user.global_admin?

    user.has_role?(:owner, project) || user.has_role?(:coworker, project)
  end

  def index?
    user_can_access_chats?
  end

  def show?
    owner_or_admin?
  end

  def new?
    create?
  end

  def create?
    user_can_manage_chats?
  end

  def update?
    owner_only?
  end

  def destroy?
    owner_only?
  end

  def send_message?
    owner_only? && record.active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if global_admin?
        # Admins can see all chats in the current project for support
        scope.all
      else
        # Regular users only see their own chats
        scope.for_user(user)
      end
    end
  end

  private

  def owner_only?
    record.owned_by?(user)
  end

  def owner_or_admin?
    owner_only? || global_admin?
  end

  def user_can_access_chats?
    return true if global_admin?

    project = ActsAsTenant.current_tenant
    return false unless project

    # Only owners and coworkers can access chats (not clients)
    user.has_role?(:owner, project) ||
      user.has_role?(:coworker, project)
  end

  # Alias - same permissions for access and management
  alias_method :user_can_manage_chats?, :user_can_access_chats?
end
