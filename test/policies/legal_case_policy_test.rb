# frozen_string_literal: true

require "test_helper"

class LegalCasePolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @legal_case = legal_cases(:legal_case_one)
  end

  # === Index ===

  test "super_admin can index legal cases" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@super_admin, LegalCase).index?
    end
  end

  test "admin can index legal cases" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@admin, LegalCase).index?
    end
  end

  test "owner can index legal cases" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@owner, LegalCase).index?
    end
  end

  test "coworker can index legal cases" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@coworker, LegalCase).index?
    end
  end

  test "client cannot index legal cases" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@client, LegalCase).index?
    end
  end

  test "outsider cannot index legal cases" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@outsider, LegalCase).index?
    end
  end

  # === Show ===

  test "super_admin can show legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@super_admin, @legal_case).show?
    end
  end

  test "owner can show legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@owner, @legal_case).show?
    end
  end

  test "coworker can show legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@coworker, @legal_case).show?
    end
  end

  test "client cannot show legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@client, @legal_case).show?
    end
  end

  test "outsider cannot show legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@outsider, @legal_case).show?
    end
  end

  # === Create ===

  test "super_admin can create legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@super_admin, LegalCase.new).create?
    end
  end

  test "owner can create legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@owner, LegalCase.new).create?
    end
  end

  test "coworker can create legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@coworker, LegalCase.new).create?
    end
  end

  test "client cannot create legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@client, LegalCase.new).create?
    end
  end

  test "outsider cannot create legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@outsider, LegalCase.new).create?
    end
  end

  # === Update ===

  test "super_admin can update legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@super_admin, @legal_case).update?
    end
  end

  test "owner can update legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@owner, @legal_case).update?
    end
  end

  test "coworker can update legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@coworker, @legal_case).update?
    end
  end

  test "client cannot update legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@client, @legal_case).update?
    end
  end

  # === Destroy ===

  test "super_admin can destroy legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@super_admin, @legal_case).destroy?
    end
  end

  test "admin can destroy legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@admin, @legal_case).destroy?
    end
  end

  test "owner can destroy legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert LegalCasePolicy.new(@owner, @legal_case).destroy?
    end
  end

  test "coworker cannot destroy legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@coworker, @legal_case).destroy?
    end
  end

  test "client cannot destroy legal case" do
    ActsAsTenant.with_tenant(@project) do
      assert_not LegalCasePolicy.new(@client, @legal_case).destroy?
    end
  end

  # === Class Method: show_project_menu? ===

  test "show_project_menu? returns true for super_admin" do
    assert LegalCasePolicy.show_project_menu?(@super_admin, @project)
  end

  test "show_project_menu? returns true for admin" do
    assert LegalCasePolicy.show_project_menu?(@admin, @project)
  end

  test "show_project_menu? returns true for owner" do
    assert LegalCasePolicy.show_project_menu?(@owner, @project)
  end

  test "show_project_menu? returns true for coworker" do
    assert LegalCasePolicy.show_project_menu?(@coworker, @project)
  end

  test "show_project_menu? returns false for client" do
    assert_not LegalCasePolicy.show_project_menu?(@client, @project)
  end

  test "show_project_menu? returns false for outsider" do
    assert_not LegalCasePolicy.show_project_menu?(@outsider, @project)
  end

  test "show_project_menu? returns false for nil user" do
    assert_not LegalCasePolicy.show_project_menu?(nil, @project)
  end

  test "show_project_menu? returns false for nil project" do
    assert_not LegalCasePolicy.show_project_menu?(@owner, nil)
  end

  # === Scope ===

  test "scope returns kept records" do
    ActsAsTenant.with_tenant(@project) do
      discarded_case = legal_cases(:legal_case_one)
      discarded_case.discard

      scope = LegalCasePolicy::Scope.new(@owner, LegalCase).resolve

      assert scope.all?(&:kept?)
      assert_not_includes scope, discarded_case
    end
  end
end
