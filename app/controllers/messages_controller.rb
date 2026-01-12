# frozen_string_literal: true

class MessagesController < ApplicationController
  before_action :set_chat

  def create
    authorize @chat, :send_message?

    @message = @chat.messages.build(message_params)
    @message.user = current_user
    @message.role = :user_role
    @message.status = :pending

    if @message.save
      Chats::SendMessageJob.perform_later(@message.id)
      redirect_to chat_path(@chat)
    else
      redirect_to chat_path(@chat), alert: @message.errors.full_messages.to_sentence
    end
  end

  private

  def set_chat
    @chat = policy_scope(Chat).kept.find(params[:chat_id])
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
