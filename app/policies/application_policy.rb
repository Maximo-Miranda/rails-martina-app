# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  # Helpers para verificar roles
  def super_admin? = user.super_admin?
  def admin? = user.admin?
  def global_admin? = user.global_admin?

  def owner?
    project = ActsAsTenant.current_tenant || user.current_project
    project && user.owner_of?(project)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end

    def global_admin? = user.global_admin?
  end
end
