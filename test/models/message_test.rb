# frozen_string_literal: true

require "test_helper"

class MessageTest < ActiveSupport::TestCase
  setup do
    @chat = chats(:user_chat)
    @user = users(:confirmed_user)
  end

  # === VALIDATIONS ===

  test "valid user message" do
    message = Message.new(
      chat: @chat,
      user: @user,
      role: :user_role,
      content: "¿Cuáles son los requisitos para un contrato?"
    )

    assert message.valid?
    assert_equal "pending", message.status
  end

  test "valid assistant message without user" do
    message = Message.new(
      chat: @chat,
      user: nil,
      role: :assistant_role,
      content: "Los requisitos son..."
    )

    assert message.valid?
  end

  test "requires role" do
    message = Message.new(chat: @chat, content: "Test")

    assert message.invalid?
    assert_includes message.errors.attribute_names, :role
  end

  test "requires content" do
    message = Message.new(chat: @chat, user: @user, role: :user_role, content: nil)

    assert message.invalid?
    assert_includes message.errors.attribute_names, :content
  end

  test "user message requires user" do
    message = Message.new(chat: @chat, user: nil, role: :user_role, content: "Test")

    assert message.invalid?
    assert_includes message.errors.attribute_names, :user
  end

  # === ASSOCIATIONS ===

  test "belongs to chat with counter cache" do
    message = messages(:user_message_one)
    assert_equal chats(:user_chat), message.chat
  end

  test "belongs to user optionally" do
    user_message = messages(:user_message_one)
    model_message = messages(:model_response_one)

    assert_equal users(:confirmed_user), user_message.user
    assert_nil model_message.user
  end

  test "has many message_citations" do
    message = messages(:model_response_one)
    assert_respond_to message, :message_citations
  end

  # === SCOPES ===

  test "for_context scope limits and orders messages" do
    messages = @chat.messages.for_context

    assert messages.count <= Chat::MAX_HISTORY_MESSAGES
  end

  test "user_messages scope" do
    user_messages = @chat.messages.user_messages

    assert user_messages.all?(&:role_user_role?)
  end

  test "assistant_messages scope" do
    assistant_messages = @chat.messages.assistant_messages

    assert assistant_messages.all?(&:role_assistant_role?)
  end

  test "kept scope excludes soft-deleted messages" do
    message = messages(:user_message_one)
    message.discard

    assert_not @chat.messages.kept.include?(message)
  end

  # === INSTANCE METHODS ===

  test "from_user? returns true for user role" do
    message = messages(:user_message_one)
    assert message.from_user?
    assert_not message.from_assistant?
  end

  test "from_assistant? returns true for assistant role" do
    message = messages(:model_response_one)
    assert message.from_assistant?
    assert_not message.from_user?
  end

  test "gemini_role returns correct role string" do
    user_message = messages(:user_message_one)
    assistant_message = messages(:model_response_one)

    assert_equal "user", user_message.gemini_role
    assert_equal "model", assistant_message.gemini_role
  end

  # === STATUS TRANSITIONS ===

  test "status transitions" do
    message = Message.create!(
      chat: @chat,
      user: @user,
      role: :user_role,
      content: "Test question"
    )

    assert message.status_pending?

    message.status_processing!
    assert message.status_processing?

    message.status_completed!
    assert message.status_completed?
  end

  test "can mark as failed" do
    message = Message.create!(
      chat: @chat,
      role: :assistant_role,
      content: "Processing..."
    )

    message.status_failed!
    assert message.status_failed?
  end

  # === SOFT DELETE ===

  test "discard soft deletes the message" do
    message = messages(:user_message_one)
    message.discard

    assert message.discarded?
    assert_not_nil message.deleted_at
  end
end
