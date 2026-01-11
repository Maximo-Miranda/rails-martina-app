# frozen_string_literal: true

module Chats
  class SendMessageJob < ApplicationJob
    queue_as :default

    # Retry on rate limiting and server errors (with polynomially increasing wait)
    retry_on Gemini::ChatService::ChatError,
             wait: :polynomially_longer,
             attempts: 3

    discard_on ActiveRecord::RecordNotFound

    def perform(message_id)
      @user_message = Message.find(message_id)
      @chat = @user_message.chat

      return if @user_message.status_completed? || @user_message.status_failed?

      @user_message.update!(status: :processing)
      broadcast_status_update(:processing)

      process_message
    rescue Gemini::ChatService::ChatError => e
      handle_chat_error(e)
      # Only re-raise retriable errors to trigger retry
      raise if retriable_error?(e)
    rescue StandardError => e
      handle_unexpected_error(e)
      raise
    end

    private

    def process_message
      result = Gemini::ChatService.send_message(
        chat: @chat,
        user_message: @user_message.content
      )

      create_assistant_message(result)
      complete_user_message(result)
    end

    def create_assistant_message(result)
      Rails.logger.info "[SendMessageJob] Creating assistant message with #{result[:citations]&.size || 0} citations"

      @assistant_message = Message.create!(
        chat: @chat,
        role: :assistant_role,
        content: result[:content],
        status: :completed,
        token_count: result[:token_count],
        finish_reason: result[:finish_reason],
        grounding_metadata: result[:grounding_metadata]
      )

      if result[:citations].present?
        Rails.logger.info "[SendMessageJob] Creating citations: #{result[:citations].map { |c| c[:document_id] }.inspect}"
        create_citations(result[:citations])
      else
        Rails.logger.info "[SendMessageJob] No citations to create"
      end

      broadcast_assistant_message
    end

    def create_citations(citations)
      citations.each do |citation|
        MessageCitation.create!(
          message: @assistant_message,
          document_id: citation[:document_id],
          pages: citation[:pages],
          text_snippet: citation[:text_snippet],
          confidence_score: citation[:confidence_score]
        )
      end
    end

    def complete_user_message(result)
      @user_message.update!(
        status: :completed,
        token_count: result[:token_count]
      )
      broadcast_status_update(:completed)
    end

    def handle_chat_error(error)
      Rails.logger.error("[SendMessageJob] ChatError for message #{@user_message.id}: #{error.message}")

      error_content = error_message_for(error)

      @assistant_message = Message.create!(
        chat: @chat,
        role: :assistant_role,
        content: error_content,
        status: :failed,
        finish_reason: error.finish_reason,
        error_message: error.message
      )

      @user_message.update!(
        status: :failed,
        error_message: error.message
      )

      broadcast_error_message(:api_error)
    end

    def handle_unexpected_error(error)
      Rails.logger.error("[SendMessageJob] Unexpected error for message #{@user_message.id}: #{error.class} - #{error.message}")
      Rails.logger.error(error.backtrace&.first(10)&.join("\n"))

      @user_message.update!(
        status: :failed,
        error_message: error.message
      )

      broadcast_error_message(:unexpected_error)
    end

    def error_message_for(error)
      case error.status
      when 429
        I18n.t("chats.errors.rate_limited")
      else
        I18n.t("chats.errors.api_error")
      end
    end

    def broadcast_status_update(status)
      ChatsChannel.broadcast_to(
        @chat,
        type: "message_status",
        message_id: @user_message.id,
        status: status
      )
    end

    def broadcast_assistant_message
      ChatsChannel.broadcast_to(
        @chat,
        type: "new_message",
        message: message_payload(@assistant_message),
        citations: citations_payload
      )
    end

    def message_payload(message)
      {
        id: message.id,
        role: message.role,
        content: message.content,
        status: message.status,
        token_count: message.token_count,
        created_at: message.created_at.iso8601,
      }
    end

    def citations_payload
      return [] unless @assistant_message&.message_citations&.any?

      @assistant_message.message_citations.includes(:document).map(&:to_api_hash)
    end

    def broadcast_error_message(error_type)
      ChatsChannel.broadcast_to(
        @chat,
        type: "message_failed",
        message_id: @user_message.id,
        error_type: error_type,
        content: I18n.t("chats.errors.#{error_type}", chat_title: @chat.display_title)
      )
    end

    def retriable_error?(error)
      # Retry on rate limiting and server errors
      error.status.nil? || error.status >= 500 || error.status == 429
    end
  end
end
