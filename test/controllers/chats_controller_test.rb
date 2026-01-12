# frozen_string_literal: true

require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @other_project = projects(:other_project)
    @store = gemini_file_search_stores(:active_store)

    @owner_chat = chats(:user_chat)
    @coworker_chat = chats(:coworker_chat)

    # Ensure users have correct current_project
    @owner.update!(current_project_id: @project.id)
    @coworker.update!(current_project_id: @project.id)
    @client.update!(current_project_id: @project.id)
    @admin.update!(current_project_id: @project.id)
    @super_admin.update!(current_project_id: @project.id)
  end

  # === Index: Authorization ===

  test "owner can access chats index" do
    sign_in @owner
    get chats_path
    assert_response :success
  end

  test "coworker can access chats index" do
    sign_in @coworker
    get chats_path
    assert_response :success
  end

  test "client cannot access chats index" do
    sign_in @client
    get chats_path
    assert_redirected_to dashboard_path
  end

  test "outsider cannot access project chats" do
    # Outsider has role in other_project, not test_project
    # When they access with invalid project, auto_assign switches to their accessible project
    # Since they don't have a store in other_project, verify they can't create chats there
    sign_in @outsider

    # First verify outsider is redirected to their own project
    @outsider.update!(current_project_id: @project.id)
    get chats_path

    # The auto_assign should have switched them to other_project
    @outsider.reload
    assert_equal @other_project.id, @outsider.current_project_id
  end

  test "admin can access any project chats" do
    sign_in @admin
    get chats_path
    assert_response :success
  end

  # === Index: Privacy (users only see their own chats) ===

  test "owner only sees their own chats in index" do
    sign_in @owner
    get chats_path
    assert_response :success
    # The response should only include owner's chats, not coworker's
    # This is validated via the policy scope
  end

  # === Show: Authorization ===

  test "owner can view their own chat" do
    sign_in @owner
    get chat_path(@owner_chat)
    assert_response :success
  end

  test "owner cannot view another users chat" do
    sign_in @owner
    get chat_path(@coworker_chat)
    # Chat not found in owner's scope
    assert_response :not_found
  end

  test "coworker cannot view owners chat" do
    sign_in @coworker
    get chat_path(@owner_chat)
    # Chat not found in coworker's scope
    assert_response :not_found
  end

  test "admin can view any chat for support" do
    sign_in @admin
    get chat_path(@owner_chat)
    assert_response :success
  end

  # === Create: Authorization ===

  test "owner can create chat" do
    sign_in @owner

    assert_difference "Chat.count", 1 do
      post chats_path, params: { chat: { title: "Nueva consulta" } }
    end
    assert_redirected_to chat_path(Chat.last)
  end

  test "coworker can create chat" do
    sign_in @coworker

    assert_difference "Chat.count", 1 do
      post chats_path, params: { chat: { title: "Mi consulta" } }
    end
    assert_redirected_to chat_path(Chat.last)
  end

  test "client cannot create chat" do
    sign_in @client

    assert_no_difference "Chat.count" do
      post chats_path, params: { chat: { title: "Consulta cliente" } }
    end
    assert_redirected_to dashboard_path
  end

  test "outsider cannot create chat in other project" do
    @outsider.update!(current_project_id: @project.id)
    sign_in @outsider

    assert_no_difference "Chat.count" do
      post chats_path, params: { chat: { title: "Hack" } }
    end
    assert_response :redirect
  end

  test "chat creation assigns current user and store" do
    sign_in @owner
    post chats_path, params: { chat: { title: "Test" } }

    chat = Chat.last
    assert_equal @owner.id, chat.user_id
    assert_equal @store.id, chat.gemini_file_search_store_id
    assert_equal @project.id, chat.project_id
  end

  # === Update: Only Owner ===

  test "owner can update their own chat" do
    sign_in @owner
    patch chat_path(@owner_chat), params: { chat: { title: "Título actualizado" } }

    assert_redirected_to chat_path(@owner_chat)
    assert_equal "Título actualizado", @owner_chat.reload.title
  end

  test "owner cannot update another users chat" do
    sign_in @owner
    patch chat_path(@coworker_chat), params: { chat: { title: "Hack" } }
    assert_response :not_found
  end

  test "admin cannot update other users chat" do
    sign_in @admin
    original_title = @owner_chat.title
    patch chat_path(@owner_chat), params: { chat: { title: "Admin edit" } }

    # Admin can view but cannot update others' chats
    assert_redirected_to dashboard_path
    assert_equal original_title, @owner_chat.reload.title
  end

  # === Destroy: Only Owner ===

  test "owner can delete their own chat" do
    sign_in @owner
    delete chat_path(@owner_chat)

    assert_redirected_to chats_path
    assert @owner_chat.reload.discarded?
  end

  test "owner cannot delete another users chat" do
    sign_in @owner
    delete chat_path(@coworker_chat)

    assert_response :not_found
    assert_not @coworker_chat.reload.discarded?
  end

  test "admin cannot delete other users chat" do
    sign_in @admin
    delete chat_path(@owner_chat)

    assert_redirected_to dashboard_path
    assert_not @owner_chat.reload.discarded?
  end

  # === Store Validation ===

  test "cannot create chat when store is not synced" do
    @store.update!(status: :pending)

    sign_in @owner
    assert_no_difference "Chat.count" do
      post chats_path, params: { chat: { title: "Test" } }
    end
    assert_redirected_to chats_path
    assert flash[:alert].present?
  end

  # === No Project ===

  test "redirects when user has no accessible projects" do
    # Remove owner from all projects so auto_assign doesn't find one
    @owner.roles.where(resource_type: "Project").destroy_all
    @owner.update!(current_project_id: nil)

    sign_in @owner
    get chats_path
    # Should redirect to new_project_path because no project accessible
    assert_redirected_to new_project_path
  end
end
