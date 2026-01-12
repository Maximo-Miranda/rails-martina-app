# frozen_string_literal: true

class ChatsController < ApplicationController
  include RansackPagyIndex

  before_action :set_chat, only: %i[show update destroy]
  before_action :set_store, only: %i[new create]

  def index
    authorize Chat

    @q, filters = build_ransack(
      policy_scope(Chat).kept,
      allowed_q_keys: %i[title_cont status_eq],
      allowed_sort_fields: %w[title status created_at updated_at],
      default_sort: "updated_at desc"
    )

    @pagy, chats = pagy(:offset, @q.result(distinct: true), limit: pagy_limit(default: 10))

    render inertia: "Chats/Index", props: {
      project: project_json(current_project),
      chats: chats_json(chats),
      pagination: pagy_pagination(@pagy),
      filters: filters,
      store: store_json(current_project_store),
      canCreateChat: policy(Chat).create? && current_project_store&.synced?,
    }
  end

  def show
    authorize @chat

    render inertia: "Chats/Show", props: {
      project: project_json(current_project),
      chat: chat_json(@chat),
      messages: messages_json(@chat.messages.kept.includes(:message_citations).order(:created_at)),
      store: store_json(@chat.gemini_file_search_store),
      chatGlobalStores: chat_global_stores_json(@chat),
      globalStores: global_stores_json,
      canSendMessage: policy(@chat).send_message?,
      canEditGlobalStores: policy(@chat).update?,
    }
  end

  def new
    @chat = current_user.chats.build(gemini_file_search_store: @store)
    authorize @chat

    render inertia: "Chats/Form", props: {
      project: project_json(current_project),
      chat: { title: nil, global_store_ids: [] },
      store: store_json(@store),
      globalStores: global_stores_json,
    }
  end

  def create
    @chat = current_user.chats.build(chat_params)
    @chat.gemini_file_search_store = @store
    assign_global_stores(@chat)
    authorize @chat

    if @chat.save
      redirect_to chat_path(@chat), notice: t(".success")
    else
      redirect_to chats_path, alert: @chat.errors.full_messages.to_sentence
    end
  end

  def update
    authorize @chat

    assign_global_stores(@chat) if params[:chat]&.key?(:global_store_ids)

    if @chat.update(chat_update_params)
      redirect_to chat_path(@chat), notice: t(".success")
    else
      redirect_to chat_path(@chat), alert: @chat.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize @chat

    @chat.discard!
    redirect_to chats_path, notice: t(".success")
  end

  private

  def set_chat
    @chat = policy_scope(Chat).kept.find(params[:id])
  end

  def set_store
    @store = current_project_store
    return if @store&.synced?

    redirect_to chats_path, alert: t("chats.errors.store_not_synced")
  end

  def current_project_store
    @current_project_store ||= current_project.gemini_file_search_store
  end

  def chat_params
    params.require(:chat).permit(:title)
  end

  def chat_update_params
    params.require(:chat).permit(:title, :status)
  end

  def assign_global_stores(chat)
    ids = params[:chat][:global_store_ids]&.reject(&:blank?)&.map(&:to_i) || []
    ActsAsTenant.without_tenant do
      chat.global_stores = GeminiFileSearchStore.kept.global.active.where(id: ids)
    end
  end

  def project_json(project)
    return nil unless project

    project.as_json(only: %i[id name slug])
  end

  def store_json(store)
    return nil unless store

    store.as_json(only: %i[id display_name status active_documents_count])
  end

  def global_stores_json
    ActsAsTenant.without_tenant do
      GeminiFileSearchStore.kept.global.active.order(:display_name).map { |s| global_store_json(s) }
    end
  end

  def chat_global_stores_json(chat)
    ActsAsTenant.without_tenant do
      chat.global_stores.reload.map { |s| global_store_json(s) }
    end
  end

  def global_store_json(store)
    store.as_json(only: %i[id display_name active_documents_count])
  end

  def chats_json(chats)
    chats.map { |chat| chat_summary_json(chat) }
  end

  def chat_summary_json(chat)
    {
      id: chat.id,
      title: chat.display_title,
      status: chat.status,
      messages_count: chat.messages.kept.count,
      last_message_at: chat.messages.kept.maximum(:created_at)&.iso8601,
      created_at: chat.created_at.iso8601,
      updated_at: chat.updated_at.iso8601,
    }
  end

  def chat_json(chat)
    {
      id: chat.id,
      title: chat.display_title,
      status: chat.status,
      created_at: chat.created_at.iso8601,
      updated_at: chat.updated_at.iso8601,
    }
  end

  def messages_json(messages)
    messages.map { |msg| message_json(msg) }
  end

  def message_json(message)
    {
      id: message.id,
      role: message.role,
      content: message.content,
      status: message.status,
      token_count: message.token_count,
      created_at: message.created_at.iso8601,
      citations: citations_json(message.message_citations),
    }
  end

  def citations_json(citations)
    citations.map(&:to_api_hash)
  end
end
