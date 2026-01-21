# frozen_string_literal: true

require "test_helper"

class CourtOrderPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @court_order = court_orders(:auto_pruebas)
  end

  # === Index ===

  test "super_admin can index court orders" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@super_admin, CourtOrder).index?
    end
  end

  test "owner can index court orders" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@owner, CourtOrder).index?
    end
  end

  test "coworker can index court orders" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@coworker, CourtOrder).index?
    end
  end

  test "client cannot index court orders" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CourtOrderPolicy.new(@client, CourtOrder).index?
    end
  end

  # === Show ===

  test "owner can show court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@owner, @court_order).show?
    end
  end

  test "coworker can show court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@coworker, @court_order).show?
    end
  end

  test "client cannot show court order" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CourtOrderPolicy.new(@client, @court_order).show?
    end
  end

  # === Create ===

  test "owner can create court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@owner, CourtOrder.new).create?
    end
  end

  test "coworker can create court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@coworker, CourtOrder.new).create?
    end
  end

  test "client cannot create court order" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CourtOrderPolicy.new(@client, CourtOrder.new).create?
    end
  end

  # === Update ===

  test "owner can update court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@owner, @court_order).update?
    end
  end

  test "coworker can update court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@coworker, @court_order).update?
    end
  end

  test "client cannot update court order" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CourtOrderPolicy.new(@client, @court_order).update?
    end
  end

  # === Destroy ===

  test "owner can destroy court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@owner, @court_order).destroy?
    end
  end

  test "coworker can destroy court order" do
    ActsAsTenant.with_tenant(@project) do
      assert CourtOrderPolicy.new(@coworker, @court_order).destroy?
    end
  end

  test "client cannot destroy court order" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CourtOrderPolicy.new(@client, @court_order).destroy?
    end
  end

  # === Scope ===

  test "scope returns kept records" do
    ActsAsTenant.with_tenant(@project) do
      scope = CourtOrderPolicy::Scope.new(@owner, CourtOrder).resolve

      assert scope.all?(&:kept?)
    end
  end
end
