# frozen_string_literal: true

class ChatsChannel < ApplicationCable::Channel
  def subscribed
    @chat = find_chat
    return reject unless @chat && authorized?

    stream_for @chat
  end

  def unsubscribed
    stop_all_streams
  end

  def send_message(data)
    data = data.with_indifferent_access
    unless @chat && authorized?
      broadcast_error(I18n.t("chats.channel.unauthorized"))
      return
    end

    content = data[:content]&.strip
    if content.blank?
      broadcast_error(I18n.t("chats.channel.message_empty"))
      return
    end

    user_message = create_user_message(content)
    broadcast_user_message(user_message)
    enqueue_processing(user_message)
  end

  private

  def find_chat
    chat_id = params[:chat_id]
    return nil unless chat_id

    Chat.kept.find_by(id: chat_id)
  end

  def authorized?
    return false unless @chat

    @chat.owned_by?(current_user)
  end

  def create_user_message(content)
    Message.create!(
      chat: @chat,
      user: current_user,
      role: :user_role,
      content: content,
      status: :pending
    )
  end

  def broadcast_user_message(message)
    # Uses ChatsChannel.broadcast_to to notifying user web instances subscribers in the private chat.
    ChatsChannel.broadcast_to(
      @chat,
      type: "new_message",
      message: {
        id: message.id,
        role: message.role,
        content: message.content,
        status: message.status,
        user_id: message.user_id,
        user_name: message.user&.full_name,
        created_at: message.created_at.iso8601,
      }
    )
  end

  def enqueue_processing(message)
    Chats::SendMessageJob.perform_later(message.id)
  end

  def broadcast_error(error_message)
    # Uses transmit to send error only to the current connection, not all user sessions.
    transmit({ type: "error", message: error_message })
  end
end
