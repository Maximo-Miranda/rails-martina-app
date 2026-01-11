# frozen_string_literal: true

require "test_helper"

class ChatTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @store = gemini_file_search_stores(:active_store)
  end

  # === VALIDATIONS ===

  test "valid chat" do
    chat = Chat.new(
      project: @project,
      user: @user,
      gemini_file_search_store: @store,
      title: "Test Chat"
    )

    assert chat.valid?
    assert_equal "active", chat.status
  end

  test "requires project" do
    chat = Chat.new(user: @user, gemini_file_search_store: @store)

    assert chat.invalid?
    assert_includes chat.errors.attribute_names, :project_id
  end

  test "requires user" do
    chat = Chat.new(project: @project, gemini_file_search_store: @store)

    assert chat.invalid?
    assert_includes chat.errors.attribute_names, :user_id
  end

  test "requires gemini_file_search_store" do
    chat = Chat.new(project: @project, user: @user)

    assert chat.invalid?
    assert_includes chat.errors.attribute_names, :gemini_file_search_store_id
  end

  test "store must be synced" do
    pending_store = gemini_file_search_stores(:pending_store)
    chat = Chat.new(
      project: projects(:pending_project),
      user: @user,
      gemini_file_search_store: pending_store
    )

    assert chat.invalid?
    assert_includes chat.errors.attribute_names, :gemini_file_search_store
  end

  test "store must have documents" do
    empty_store = gemini_file_search_stores(:empty_active_store)
    chat = Chat.new(
      project: projects(:empty_store_project),
      user: @user,
      gemini_file_search_store: empty_store
    )

    assert chat.invalid?
    assert_includes chat.errors.attribute_names, :gemini_file_search_store
    assert chat.errors[:gemini_file_search_store].any? { |msg| msg.include?("no tiene documentos") }
  end

  test "enforces max chats per project limit" do
    Chat.where(project: @project).destroy_all

    Chat::MAX_CHATS_PER_PROJECT.times do |i|
      Chat.create!(
        project: @project,
        user: @user,
        gemini_file_search_store: @store,
        title: "Chat #{i}"
      )
    end

    chat = Chat.new(
      project: @project,
      user: @user,
      gemini_file_search_store: @store,
      title: "Chat over limit"
    )

    assert chat.invalid?
    assert_includes chat.errors.attribute_names, :base

    expected_message = I18n.t(
      "activerecord.errors.models.chat.attributes.base.max_chats_reached",
      count: Chat::MAX_CHATS_PER_PROJECT
    )
    assert_includes chat.errors.full_messages, expected_message
  end

  # === ASSOCIATIONS ===

  test "belongs to project" do
    chat = chats(:user_chat)
    assert_equal projects(:test_project), chat.project
  end

  test "belongs to user (private chats)" do
    chat = chats(:user_chat)
    assert_equal users(:confirmed_user), chat.user
  end

  test "belongs to gemini_file_search_store" do
    chat = chats(:user_chat)
    assert_equal gemini_file_search_stores(:active_store), chat.gemini_file_search_store
  end

  test "has many messages" do
    chat = chats(:user_chat)
    assert_respond_to chat, :messages
  end

  # === SCOPES ===

  test "for_user scope returns only user's chats" do
    user_chats = Chat.for_user(users(:confirmed_user))
    coworker_chats = Chat.for_user(users(:coworker_user))

    assert user_chats.include?(chats(:user_chat))
    assert_not user_chats.include?(chats(:coworker_chat))
    assert coworker_chats.include?(chats(:coworker_chat))
  end

  test "for_project scope" do
    project_chats = Chat.for_project(projects(:test_project))

    assert project_chats.include?(chats(:user_chat))
    assert project_chats.include?(chats(:coworker_chat))
  end

  test "kept scope excludes soft-deleted chats" do
    assert Chat.kept.include?(chats(:user_chat))
    assert_not Chat.kept.include?(chats(:deleted_chat))
  end

  # === INSTANCE METHODS ===

  test "owned_by? returns true for owner" do
    chat = chats(:user_chat)
    assert chat.owned_by?(users(:confirmed_user))
  end

  test "owned_by? returns false for other users" do
    chat = chats(:user_chat)
    assert_not chat.owned_by?(users(:coworker_user))
  end

  test "history_for_context returns limited messages" do
    chat = chats(:user_chat)
    history = chat.history_for_context

    assert_kind_of Array, history
    assert history.all? { |msg| msg.key?(:role) && msg.key?(:content) }
  end

  test "generate_title_from_first_message sets title from first user message" do
    chat = Chat.create!(
      project: @project,
      user: @user,
      gemini_file_search_store: @store,
      title: nil
    )

    chat.messages.create!(
      user: @user,
      role: :user_role,
      content: "¿Requisitos contrato arrendamiento?",
      status: :completed
    )

    chat.generate_title_from_first_message

    assert_equal "¿Requisitos contrato arrendamiento?", chat.title
  end

  test "generate_title_from_first_message truncates at word boundary" do
    chat = Chat.create!(
      project: @project,
      user: @user,
      gemini_file_search_store: @store,
      title: nil
    )

    long_content = "¿Cuáles son los requisitos legales para un contrato de arrendamiento de vivienda urbana en Colombia según la Ley 820?"
    chat.messages.create!(
      user: @user,
      role: :user_role,
      content: long_content,
      status: :completed
    )

    chat.generate_title_from_first_message

    assert chat.title.length <= 50
    assert chat.title.end_with?("…")
    assert_not chat.title.end_with?(" …")
  end

  test "display_title returns title or fallback" do
    chat_with_title = chats(:user_chat)
    chat_without_title = Chat.new(title: nil)

    assert_equal "Consulta sobre contratos", chat_with_title.display_title
    assert_equal I18n.t("chats.default_title"), chat_without_title.display_title
  end

  # === SOFT DELETE ===

  test "discard soft deletes the chat" do
    chat = chats(:user_chat)
    chat.discard

    assert chat.discarded?
    assert_not_nil chat.deleted_at
  end
end
