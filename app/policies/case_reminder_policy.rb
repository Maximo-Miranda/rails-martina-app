# frozen_string_literal: true

class CaseReminderPolicy < ApplicationPolicy
  def index?
    user_has_project_access?
  end

  def show?
    user_has_project_access?
  end

  def create?
    user_can_edit_project?
  end

  def update?
    user_can_edit_project?
  end

  def destroy?
    user_can_edit_project?
  end

  def acknowledge?
    return false unless user

    record.case_reminder_users.exists?(user: user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.kept
    end
  end

  private

  def user_has_project_access?
    return false unless user

    global_admin? || owner? || coworker?
  end

  def user_can_edit_project?
    user_has_project_access?
  end
end
