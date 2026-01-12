# frozen_string_literal: true

require "test_helper"

class ChatsChannelTest < ActionCable::Channel::TestCase
  include ActiveJob::TestHelper

  def setup
    @chat = chats(:user_chat)
    @user = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @outsider = users(:outsider_user)

    stub_connection(current_user: @user)
  end

  # === Subscription Tests ===

  test "subscribes to chat as owner" do
    subscribe(chat_id: @chat.id)

    assert subscription.confirmed?
    assert_has_stream_for @chat
  end

  test "rejects subscription for project coworker (chat is private)" do
    stub_connection(current_user: @coworker)
    subscribe(chat_id: @chat.id)

    assert subscription.rejected?
  end

  test "rejects subscription without chat_id" do
    subscribe(chat_id: nil)

    assert subscription.rejected?
  end

  test "rejects subscription for non-existent chat" do
    subscribe(chat_id: -1)

    assert subscription.rejected?
  end

  test "rejects subscription for deleted chat" do
    deleted_chat = chats(:deleted_chat)
    subscribe(chat_id: deleted_chat.id)

    assert subscription.rejected?
  end

  test "rejects subscription for unauthorized user" do
    stub_connection(current_user: @outsider)
    subscribe(chat_id: @chat.id)

    assert subscription.rejected?
  end

  # === Send Message Tests ===

  test "send_message creates user message and enqueues job" do
    subscribe(chat_id: @chat.id)

    assert_enqueued_with(job: Chats::SendMessageJob) do
      perform :send_message, content: "¿Cuáles son los requisitos?"
    end

    message = @chat.messages.order(:created_at).last
    assert_equal "¿Cuáles son los requisitos?", message.content
    assert_equal "user_role", message.role
    assert_equal @user.id, message.user_id
    assert_equal "pending", message.status
  end

  test "send_message strips whitespace from content" do
    subscribe(chat_id: @chat.id)

    perform :send_message, content: "  Pregunta con espacios  "

    message = @chat.messages.order(:created_at).last
    assert_equal "Pregunta con espacios", message.content
  end

  test "send_message broadcasts user message" do
    subscribe(chat_id: @chat.id)

    perform :send_message, content: "Test message"

    # Check that a broadcast was sent with the expected type
    assert_broadcasts(@chat, 1)
  end

  test "send_message transmits error for empty content" do
    subscribe(chat_id: @chat.id)

    perform :send_message, content: ""

    assert_equal 1, transmissions.size
    transmission = transmissions.first
    assert_equal "error", transmission["type"]
    assert_equal I18n.t("chats.channel.message_empty"), transmission["message"]
  end

  test "send_message transmits error for whitespace-only content" do
    subscribe(chat_id: @chat.id)

    perform :send_message, content: "   "

    assert_equal 1, transmissions.size
    transmission = transmissions.first
    assert_equal "error", transmission["type"]
    assert_equal I18n.t("chats.channel.message_empty"), transmission["message"]
  end

  # === Unsubscribe Tests ===

  test "unsubscribed stops all streams" do
    subscribe(chat_id: @chat.id)
    assert_has_stream_for @chat

    unsubscribe

    assert_no_streams
  end
end
