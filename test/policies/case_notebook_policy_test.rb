# frozen_string_literal: true

require "test_helper"

class CaseNotebookPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @notebook = case_notebooks(:principal_notebook)
  end

  # === Index ===

  test "super_admin can index case notebooks" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@super_admin, CaseNotebook).index?
    end
  end

  test "owner can index case notebooks" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@owner, CaseNotebook).index?
    end
  end

  test "coworker can index case notebooks" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@coworker, CaseNotebook).index?
    end
  end

  test "client cannot index case notebooks" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@client, CaseNotebook).index?
    end
  end

  test "outsider cannot index case notebooks" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@outsider, CaseNotebook).index?
    end
  end

  # === Show ===

  test "owner can show case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@owner, @notebook).show?
    end
  end

  test "coworker can show case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@coworker, @notebook).show?
    end
  end

  test "client cannot show case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@client, @notebook).show?
    end
  end

  # === Create ===

  test "super_admin can create case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@super_admin, CaseNotebook.new).create?
    end
  end

  test "owner can create case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@owner, CaseNotebook.new).create?
    end
  end

  test "coworker can create case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@coworker, CaseNotebook.new).create?
    end
  end

  test "client cannot create case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@client, CaseNotebook.new).create?
    end
  end

  # === Update ===

  test "owner can update case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@owner, @notebook).update?
    end
  end

  test "coworker can update case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@coworker, @notebook).update?
    end
  end

  test "client cannot update case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@client, @notebook).update?
    end
  end

  # === Destroy ===

  test "super_admin can destroy case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@super_admin, @notebook).destroy?
    end
  end

  test "admin can destroy case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@admin, @notebook).destroy?
    end
  end

  test "owner can destroy case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseNotebookPolicy.new(@owner, @notebook).destroy?
    end
  end

  test "coworker cannot destroy case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@coworker, @notebook).destroy?
    end
  end

  test "client cannot destroy case notebook" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseNotebookPolicy.new(@client, @notebook).destroy?
    end
  end

  # === Scope ===

  test "scope returns kept records" do
    ActsAsTenant.with_tenant(@project) do
      scope = CaseNotebookPolicy::Scope.new(@owner, CaseNotebook).resolve

      assert scope.all?(&:kept?)
    end
  end
end
