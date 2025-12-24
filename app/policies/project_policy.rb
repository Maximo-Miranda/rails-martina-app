# frozen_string_literal: true

class ProjectPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    global_admin? || user.member_of?(record)
  end

  def create?
    true
  end

  def update?
    global_admin? || user.owner_of?(record)
  end

  def destroy?
    global_admin? || user.owner_of?(record)
  end

  def switch?
    global_admin? || user.member_of?(record)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if global_admin?
        scope.kept
      else
        scope.kept.joins(:roles).where(roles: { id: user.roles.pluck(:id) })
      end
    end
  end
end
