# frozen_string_literal: true

require "test_helper"

class ChatPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @owner_chat = chats(:user_chat)
    @coworker_chat = chats(:coworker_chat)
    @archived_chat = chats(:archived_chat)
  end

  # === Index ===

  test "owner can index chats" do
    ActsAsTenant.with_tenant(@project) do
      assert ChatPolicy.new(@owner, Chat).index?
    end
  end

  test "coworker can index chats" do
    ActsAsTenant.with_tenant(@project) do
      assert ChatPolicy.new(@coworker, Chat).index?
    end
  end

  test "client cannot index chats" do
    ActsAsTenant.with_tenant(@project) do
      assert_not ChatPolicy.new(@client, Chat).index?
    end
  end

  test "outsider cannot index chats" do
    ActsAsTenant.with_tenant(@project) do
      assert_not ChatPolicy.new(@outsider, Chat).index?
    end
  end

  test "admin can index chats" do
    ActsAsTenant.with_tenant(@project) do
      assert ChatPolicy.new(@admin, Chat).index?
    end
  end

  # === Show ===

  test "owner can show their own chat" do
    assert ChatPolicy.new(@owner, @owner_chat).show?
  end

  test "owner cannot show another users chat" do
    assert_not ChatPolicy.new(@owner, @coworker_chat).show?
  end

  test "coworker cannot show owners chat" do
    assert_not ChatPolicy.new(@coworker, @owner_chat).show?
  end

  test "admin can show any chat" do
    assert ChatPolicy.new(@admin, @owner_chat).show?
    assert ChatPolicy.new(@admin, @coworker_chat).show?
  end

  # === Create ===

  test "owner and coworker can create chats" do
    ActsAsTenant.with_tenant(@project) do
      assert ChatPolicy.new(@owner, Chat.new).create?
      assert ChatPolicy.new(@coworker, Chat.new).create?
    end
  end

  test "client cannot create chat" do
    ActsAsTenant.with_tenant(@project) do
      assert_not ChatPolicy.new(@client, Chat.new).create?
    end
  end

  test "outsider cannot create chat" do
    ActsAsTenant.with_tenant(@project) do
      assert_not ChatPolicy.new(@outsider, Chat.new).create?
    end
  end

  # === Update ===

  test "only owner can update their chat" do
    assert ChatPolicy.new(@owner, @owner_chat).update?
    assert_not ChatPolicy.new(@coworker, @owner_chat).update?
    assert_not ChatPolicy.new(@admin, @owner_chat).update?
  end

  # === Destroy ===

  test "only owner can destroy their chat" do
    assert ChatPolicy.new(@owner, @owner_chat).destroy?
    assert_not ChatPolicy.new(@coworker, @owner_chat).destroy?
    assert_not ChatPolicy.new(@admin, @owner_chat).destroy?
  end

  # === Send Message ===

  test "owner can send message to active chat" do
    assert ChatPolicy.new(@owner, @owner_chat).send_message?
  end

  test "owner cannot send message to archived chat" do
    assert_not ChatPolicy.new(@owner, @archived_chat).send_message?
  end

  test "non-owner cannot send message" do
    assert_not ChatPolicy.new(@coworker, @owner_chat).send_message?
    assert_not ChatPolicy.new(@admin, @owner_chat).send_message?
  end

  # === Scope ===

  test "scope returns only users own chats" do
    ActsAsTenant.with_tenant(@project) do
      owner_chats = ChatPolicy::Scope.new(@owner, Chat.kept).resolve
      assert owner_chats.all? { |chat| chat.user_id == @owner.id }

      coworker_chats = ChatPolicy::Scope.new(@coworker, Chat.kept).resolve
      assert coworker_chats.all? { |chat| chat.user_id == @coworker.id }
    end
  end

  test "admin scope returns all chats" do
    ActsAsTenant.with_tenant(@project) do
      admin_chats = ChatPolicy::Scope.new(@admin, Chat.kept).resolve
      # Admin sees all chats in project
      assert_includes admin_chats.pluck(:user_id), @owner.id
      assert_includes admin_chats.pluck(:user_id), @coworker.id
    end
  end
end
