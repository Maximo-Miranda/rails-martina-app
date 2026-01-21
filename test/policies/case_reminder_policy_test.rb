# frozen_string_literal: true

require "test_helper"

class CaseReminderPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @reminder = case_reminders(:audiencia_reminder)
  end

  # === Index ===

  test "super_admin can index case reminders" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@super_admin, CaseReminder).index?
    end
  end

  test "owner can index case reminders" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@owner, CaseReminder).index?
    end
  end

  test "coworker can index case reminders" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@coworker, CaseReminder).index?
    end
  end

  test "client cannot index case reminders" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseReminderPolicy.new(@client, CaseReminder).index?
    end
  end

  # === Show ===

  test "owner can show case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@owner, @reminder).show?
    end
  end

  test "coworker can show case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@coworker, @reminder).show?
    end
  end

  test "client cannot show case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseReminderPolicy.new(@client, @reminder).show?
    end
  end

  # === Create ===

  test "owner can create case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@owner, CaseReminder.new).create?
    end
  end

  test "coworker can create case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@coworker, CaseReminder.new).create?
    end
  end

  test "client cannot create case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseReminderPolicy.new(@client, CaseReminder.new).create?
    end
  end

  # === Update ===

  test "owner can update case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@owner, @reminder).update?
    end
  end

  test "coworker can update case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@coworker, @reminder).update?
    end
  end

  test "client cannot update case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseReminderPolicy.new(@client, @reminder).update?
    end
  end

  # === Destroy ===

  test "owner can destroy case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@owner, @reminder).destroy?
    end
  end

  test "coworker can destroy case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseReminderPolicy.new(@coworker, @reminder).destroy?
    end
  end

  test "client cannot destroy case reminder" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseReminderPolicy.new(@client, @reminder).destroy?
    end
  end

  # === Acknowledge ===

  test "acknowledge? returns true for assigned user" do
    # @owner is assigned via reminder_user_one fixture
    assert CaseReminderPolicy.new(@owner, @reminder).acknowledge?
  end

  test "acknowledge? returns true for assigned coworker" do
    # @coworker is assigned via reminder_user_coworker fixture
    assert CaseReminderPolicy.new(@coworker, @reminder).acknowledge?
  end

  test "acknowledge? returns false for non-assigned user" do
    assert_not CaseReminderPolicy.new(@client, @reminder).acknowledge?
  end

  test "acknowledge? returns false for admin not assigned" do
    assert_not CaseReminderPolicy.new(@admin, @reminder).acknowledge?
  end

  test "acknowledge? returns false for nil user" do
    assert_not CaseReminderPolicy.new(nil, @reminder).acknowledge?
  end

  # === Scope ===

  test "scope returns kept records" do
    ActsAsTenant.with_tenant(@project) do
      scope = CaseReminderPolicy::Scope.new(@owner, CaseReminder).resolve

      assert scope.all?(&:kept?)
    end
  end
end
