# frozen_string_literal: true

require "test_helper"

class Chats::SendMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @chat = chats(:user_chat)
    @user = users(:confirmed_user)
    @pending_message = messages(:pending_message)
  end

  test "processes pending message and creates assistant response" do
    mock_service_response = {
      content: "Esta es la respuesta del asistente basada en los documentos.",
      grounding_metadata: { "groundingChunks" => [] },
      citations: [],
      token_count: 50,
      finish_reason: "STOP",
    }

    Gemini::ChatService.stubs(:send_message).returns(mock_service_response)
    ChatsChannel.stubs(:broadcast_to)

    Chats::SendMessageJob.perform_now(@pending_message.id)

    @pending_message.reload
    assert_equal "completed", @pending_message.status
    assert_equal 50, @pending_message.token_count

    assistant_message = @chat.messages.where(role: :assistant_role).order(:created_at).last
    assert_not_nil assistant_message
    assert_equal "Esta es la respuesta del asistente basada en los documentos.", assistant_message.content
    assert_equal "completed", assistant_message.status
    assert_equal 50, assistant_message.token_count
    assert_equal "STOP", assistant_message.finish_reason
  end

  test "creates citations when present in response" do
    document = documents(:ley_1564_2012)

    mock_service_response = {
      content: "Según el documento, la información indica que...",
      grounding_metadata: {},
      citations: [
        {
          document_id: document.id,
          pages: [ 1, 2, 3 ],
          text_snippet: "Fragmento del documento relevante",
          confidence_score: 0.85,
        },
      ],
      token_count: 75,
      finish_reason: "STOP",
    }

    Gemini::ChatService.stubs(:send_message).returns(mock_service_response)
    ChatsChannel.stubs(:broadcast_to)

    Chats::SendMessageJob.perform_now(@pending_message.id)

    assistant_message = @chat.messages.where(role: :assistant_role).order(:created_at).last
    assert_equal 1, assistant_message.message_citations.count

    citation = assistant_message.message_citations.first
    assert_equal document.id, citation.document_id
    assert_equal [ 1, 2, 3 ], citation.pages
    assert_equal "Fragmento del documento relevante", citation.text_snippet
    assert_in_delta 0.85, citation.confidence_score, 0.01
  end

  test "skips already completed messages" do
    completed_message = messages(:user_message_one)
    assert_equal "completed", completed_message.status

    # If job runs on completed message, it should return early without calling service
    original_assistant_count = @chat.messages.where(role: :assistant_role).count

    # Service should NOT be called
    Gemini::ChatService.expects(:send_message).never

    Chats::SendMessageJob.perform_now(completed_message.id)

    # No new assistant message created
    assert_equal original_assistant_count, @chat.messages.where(role: :assistant_role).count
    completed_message.reload
    assert_equal "completed", completed_message.status
  end

  test "handles message not found gracefully" do
    # Should not raise, job is configured to discard_on RecordNotFound
    assert_nothing_raised do
      Chats::SendMessageJob.perform_now(-1)
    end
  end

  test "handles chat error and marks message as failed" do
    error = Gemini::ChatService::ChatError.new("API Error", status: 400, finish_reason: "ERROR")

    Gemini::ChatService.stubs(:send_message).raises(error)
    ChatsChannel.stubs(:broadcast_to)

    Chats::SendMessageJob.perform_now(@pending_message.id)

    @pending_message.reload
    assert_equal "failed", @pending_message.status
    assert_equal "API Error", @pending_message.error_message

    # Should create an assistant message with error
    assistant_message = @chat.messages.where(role: :assistant_role).order(:created_at).last
    assert_not_nil assistant_message
    assert_equal "failed", assistant_message.status
  end

  test "broadcasts message_failed when chat error occurs" do
    error = Gemini::ChatService::ChatError.new("Safety blocked", status: 400, finish_reason: "SAFETY")

    Gemini::ChatService.stubs(:send_message).raises(error)

    # Verify that broadcast_to is called with message_failed type
    ChatsChannel.expects(:broadcast_to).at_least_once.with do |chat, data|
      if data[:type] == "message_failed"
        assert_equal @pending_message.id, data[:message_id]
        assert_equal :api_error, data[:error_type]
        assert data[:content].present?
      end
      true
    end

    Chats::SendMessageJob.perform_now(@pending_message.id)
  end

  test "broadcasts assistant message via ChatsChannel" do
    mock_service_response = {
      content: "Respuesta del asistente",
      grounding_metadata: {},
      citations: [],
      token_count: 25,
      finish_reason: "STOP",
    }

    Gemini::ChatService.stubs(:send_message).returns(mock_service_response)

    # Verify that broadcast_to is called with expected data
    ChatsChannel.expects(:broadcast_to).at_least_once.with do |chat, data|
      if data[:type] == "new_message"
        assert_equal "Respuesta del asistente", data[:message][:content]
        assert_equal "assistant_role", data[:message][:role]
      end
      true
    end

    Chats::SendMessageJob.perform_now(@pending_message.id)
  end

  test "retriable_error? returns true for rate limiting (429)" do
    job = Chats::SendMessageJob.new
    error = Gemini::ChatService::ChatError.new("Rate limited", status: 429)
    assert job.send(:retriable_error?, error)
  end

  test "retriable_error? returns true for server errors (5xx)" do
    job = Chats::SendMessageJob.new
    error = Gemini::ChatService::ChatError.new("Server error", status: 500)
    assert job.send(:retriable_error?, error)

    error_503 = Gemini::ChatService::ChatError.new("Service unavailable", status: 503)
    assert job.send(:retriable_error?, error_503)
  end

  test "retriable_error? returns false for client errors (4xx except 429)" do
    job = Chats::SendMessageJob.new
    error = Gemini::ChatService::ChatError.new("Bad request", status: 400)
    refute job.send(:retriable_error?, error)

    error_403 = Gemini::ChatService::ChatError.new("Forbidden", status: 403)
    refute job.send(:retriable_error?, error_403)
  end
end
