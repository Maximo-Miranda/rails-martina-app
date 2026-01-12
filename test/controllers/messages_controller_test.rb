# frozen_string_literal: true

require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @admin = users(:admin_user)

    @project = projects(:test_project)
    @store = gemini_file_search_stores(:active_store)

    @owner_chat = chats(:user_chat)
    @coworker_chat = chats(:coworker_chat)
    @archived_chat = chats(:archived_chat)

    @message = messages(:user_message_one)

    # Ensure users have correct current_project
    @owner.update!(current_project_id: @project.id)
    @coworker.update!(current_project_id: @project.id)
    @admin.update!(current_project_id: @project.id)
  end

  # === Create: Authorization ===

  test "owner can send message to their own chat" do
    sign_in @owner

    assert_difference "Message.count", 1 do
      post chat_messages_path(@owner_chat), params: { message: { content: "¿Qué dice el artículo 1?" } }
    end

    message = Message.last
    assert_equal "user_role", message.role
    assert_equal "pending", message.status
  end

  test "owner cannot send message to another users chat" do
    sign_in @owner

    assert_no_difference "Message.count" do
      post chat_messages_path(@coworker_chat), params: { message: { content: "Hack" } }
    end
    assert_response :not_found
  end

  test "coworker cannot send message to owners chat" do
    sign_in @coworker

    assert_no_difference "Message.count" do
      post chat_messages_path(@owner_chat), params: { message: { content: "Hack" } }
    end
    assert_response :not_found
  end

  test "admin cannot send message to other users chat" do
    sign_in @admin

    assert_no_difference "Message.count" do
      post chat_messages_path(@owner_chat), params: { message: { content: "Admin message" } }
    end
    # Admin can view but not send messages to others' chats
    assert_redirected_to dashboard_path
  end

  # === Create: Chat Status Validation ===

  test "cannot send message to archived chat" do
    sign_in @owner

    assert_no_difference "Message.count" do
      post chat_messages_path(@archived_chat), params: { message: { content: "Test" } }
    end
    assert_redirected_to dashboard_path
  end

  # === Create: Job Enqueuing ===

  test "creating message enqueues SendMessageJob" do
    sign_in @owner

    assert_enqueued_with(job: Chats::SendMessageJob) do
      post chat_messages_path(@owner_chat), params: { message: { content: "¿Qué dice el artículo 1?" } }
    end
  end

  # === Create: Title Generation ===

  test "creates title from first message" do
    sign_in @owner

    # Create a new chat without title using ActsAsTenant for model creation
    chat = ActsAsTenant.with_tenant(@project) do
      Chat.create!(
        project: @project,
        user: @owner,
        gemini_file_search_store: @store,
        title: nil
      )
    end

    post chat_messages_path(chat), params: { message: { content: "¿Cuáles son los requisitos del artículo 123?" } }

    chat.reload
    assert chat.title.present?
    assert_includes chat.title, "requisitos"
  end
end
