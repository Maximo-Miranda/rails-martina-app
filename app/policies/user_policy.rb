# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    global_admin? || owner?
  end

  def show?
    global_admin? || owner? || record == user
  end

  def invite?
    global_admin? || owner?
  end

  def update?
    global_admin? || record == user
  end

  def destroy?
    # Solo super_admin puede eliminar usuarios (soft-delete)
    super_admin? && record != user
  end

  def remove_from_project?
    # Owner del proyecto o admin global pueden desvincular usuarios
    # No permitir desvincularse a uno mismo
    (global_admin? || owner?) && record != user
  end

  # Para mostrar/ocultar módulo usuarios en menú
  def show_menu?
    global_admin? || owner?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless ActsAsTenant.current_tenant

      scope.kept.joins(:roles).where(roles: { resource: ActsAsTenant.current_tenant }).distinct
    end
  end
end
