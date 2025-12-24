# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    super_admin? || owner?
  end

  def show?
    super_admin? || owner? || record == user
  end

  def invite?
    super_admin? || owner?
  end

  def update?
    super_admin? || record == user
  end

  def destroy?
    super_admin? && record != user
  end

  # Para mostrar/ocultar módulo usuarios en menú
  def show_menu?
    super_admin? || owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        scope.kept
      else
        # Solo usuarios del proyecto actual
        project = ActsAsTenant.current_tenant || user.current_project
        return scope.none unless project

        user_ids = Role.where(resource: project).joins(:users).pluck("users.id")
        scope.kept.where(id: user_ids)
      end
    end
  end
end
