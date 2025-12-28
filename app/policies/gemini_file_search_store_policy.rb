# frozen_string_literal: true

class GeminiFileSearchStorePolicy < ApplicationPolicy
  def index?
    admin_access?
  end

  def show?
    admin_access?
  end

  def new?
    admin_access?
  end

  def create?
    admin_access?
  end

  def edit?
    admin_access?
  end

  def update?
    admin_access?
  end

  def destroy?
    admin_access?
  end

  def show_menu?
    admin_access?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.has_any_role?(:super_admin, :admin)
        scope.global.kept
      else
        scope.none
      end
    end
  end

  private

  def admin_access?
    user.has_any_role?(:super_admin, :admin)
  end
end
