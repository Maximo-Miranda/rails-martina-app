# frozen_string_literal: true

require "test_helper"

# Unit tests for ChatService - tests internal logic without actual HTTP calls
# For integration tests with real API calls, see chat_integration_test.rb
class Gemini::ChatServiceTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @store = gemini_file_search_stores(:active_store)

    # Create a chat for testing
    @chat = Chat.new(
      project: @project,
      user: @user,
      gemini_file_search_store: @store,
      title: "Test Chat"
    )
    @chat.save!(validate: false)
  end

  # ==========================================
  # Payload Building Tests
  # ==========================================

  test "build_payload creates correct structure" do
    store_name = @store.gemini_store_name
    history = []

    payload = Gemini::ChatService.send(:build_payload, "Test question", store_name, history, {})

    # Verify system instruction
    assert payload[:systemInstruction].present?
    assert payload[:systemInstruction][:parts].first[:text].include?("asistente legal")

    # Verify contents
    assert payload[:contents].present?
    last_content = payload[:contents].last
    assert_equal "user", last_content[:role]
    assert_equal "Test question", last_content[:parts].first[:text]

    # Verify tools
    assert payload[:tools].present?
    file_search = payload[:tools].first[:file_search]
    assert_not_nil file_search
    assert_includes file_search[:file_search_store_names], store_name
    assert_equal 50, file_search[:topK]

    # Verify generation config
    config = payload[:generationConfig]
    assert_equal 0.1, config[:temperature]
    assert_equal 8192, config[:maxOutputTokens]
  end

  test "build_payload includes chat history" do
    store_name = @store.gemini_store_name
    history = [
      { role: "user", content: "Primera pregunta" },
      { role: "model", content: "Primera respuesta del asistente" },
    ]

    payload = Gemini::ChatService.send(:build_payload, "Segunda pregunta", store_name, history, {})
    contents = payload[:contents]

    # Should have history (2 messages) + new message (1)
    assert_equal 3, contents.length

    # Verify order: user, model, user
    assert_equal "user", contents[0][:role]
    assert_equal "model", contents[1][:role]
    assert_equal "user", contents[2][:role]

    # Last message should be the new one
    assert_equal "Segunda pregunta", contents.last[:parts].first[:text]
  end

  test "build_payload accepts custom generation config options" do
    store_name = @store.gemini_store_name
    history = []

    payload = Gemini::ChatService.send(:build_payload, "Test", store_name, history, {
      temperature: 0.5,
      max_output_tokens: 4096,
    })

    config = payload[:generationConfig]
    assert_equal 0.5, config[:temperature]
    assert_equal 4096, config[:maxOutputTokens]
  end

  test "build_contents converts history to Gemini format" do
    history = [
      { role: "user", content: "Pregunta" },
      { role: "model", content: "Respuesta" },
    ]

    contents = Gemini::ChatService.send(:build_contents, "Nueva pregunta", history)

    # Second message should be "model" for Gemini API
    assert_equal "model", contents[1][:role]
    assert_equal 3, contents.length
  end

  # ==========================================
  # Response Processing Tests
  # ==========================================

  test "process_response extracts content correctly" do
    response = successful_response
    result = Gemini::ChatService.send(:process_response, response, @project)

    assert_equal "El CGP es el Código General del Proceso...", result[:content]
    assert_equal "STOP", result[:finish_reason]
    assert_equal 500, result[:token_count]
  end

  test "process_response handles SAFETY finish reason" do
    response = blocked_response(finish_reason: "SAFETY")
    result = Gemini::ChatService.send(:process_response, response, @project)

    assert_equal I18n.t("chats.errors.blocked_safety"), result[:content]
    assert_equal "SAFETY", result[:finish_reason]
  end

  test "process_response handles RECITATION finish reason" do
    response = blocked_response(finish_reason: "RECITATION")
    result = Gemini::ChatService.send(:process_response, response, @project)

    assert_equal I18n.t("chats.errors.blocked_recitation"), result[:content]
  end

  test "process_response handles MAX_TOKENS finish reason" do
    response = blocked_response(finish_reason: "MAX_TOKENS")
    result = Gemini::ChatService.send(:process_response, response, @project)

    assert_equal I18n.t("chats.errors.max_tokens"), result[:content]
  end

  test "process_response handles empty content with no_relevant_info message" do
    response = {
      "candidates" => [
        {
          "content" => { "parts" => [ { "text" => "" } ] },
          "finishReason" => "STOP",
          "groundingMetadata" => {},
        },
      ],
      "usageMetadata" => { "totalTokenCount" => 100 },
    }

    result = Gemini::ChatService.send(:process_response, response, @project)
    assert_equal I18n.t("chats.errors.no_relevant_info"), result[:content]
  end

  test "process_response raises ChatError when no candidates" do
    response = { "candidates" => [] }

    assert_raises(Gemini::ChatService::ChatError) do
      Gemini::ChatService.send(:process_response, response, @project)
    end
  end

  test "process_response raises ChatError when candidates is nil" do
    response = {}

    error = assert_raises(Gemini::ChatService::ChatError) do
      Gemini::ChatService.send(:process_response, response, @project)
    end

    assert_includes error.message, "respuesta"
  end

  test "process_response extracts grounding metadata" do
    response = successful_response
    result = Gemini::ChatService.send(:process_response, response, @project)

    assert result[:grounding_metadata].present?
    assert result[:grounding_metadata]["groundingChunks"].present?
  end

  test "process_response calls CitationExtractor" do
    response = successful_response
    result = Gemini::ChatService.send(:process_response, response, @project)

    # Citations should be an array (empty since no real documents match)
    assert result[:citations].is_a?(Array)
  end

  # ==========================================
  # Empty Content Handling Tests
  # ==========================================

  test "handle_empty_content returns SAFETY message" do
    result = Gemini::ChatService.send(:handle_empty_content, "", "SAFETY")
    assert_equal I18n.t("chats.errors.blocked_safety"), result
  end

  test "handle_empty_content returns RECITATION message" do
    result = Gemini::ChatService.send(:handle_empty_content, "", "RECITATION")
    assert_equal I18n.t("chats.errors.blocked_recitation"), result
  end

  test "handle_empty_content returns MAX_TOKENS message" do
    result = Gemini::ChatService.send(:handle_empty_content, "", "MAX_TOKENS")
    assert_equal I18n.t("chats.errors.max_tokens"), result
  end

  test "handle_empty_content returns no_relevant_info for other reasons" do
    result = Gemini::ChatService.send(:handle_empty_content, "", "STOP")
    assert_equal I18n.t("chats.errors.no_relevant_info"), result
  end

  test "handle_empty_content returns content when not empty" do
    result = Gemini::ChatService.send(:handle_empty_content, "Real content", "STOP")
    assert_equal "Real content", result
  end

  # ==========================================
  # Token Count Extraction Tests
  # ==========================================

  test "extract_token_count returns total from usage metadata" do
    data = { "usageMetadata" => { "totalTokenCount" => 500 } }
    result = Gemini::ChatService.send(:extract_token_count, data)
    assert_equal 500, result
  end

  test "extract_token_count returns 0 when no metadata" do
    data = {}
    result = Gemini::ChatService.send(:extract_token_count, data)
    assert_equal 0, result
  end

  # ==========================================
  # ChatError Class Tests
  # ==========================================

  test "ChatError stores status and message" do
    error = Gemini::ChatService::ChatError.new("Error message", status: 500)

    assert_equal "Error message", error.message
    assert_equal 500, error.status
  end

  test "ChatError works with default status" do
    error = Gemini::ChatService::ChatError.new("Error message")

    assert_equal "Error message", error.message
    assert_nil error.status
  end

  test "ChatError stores body and finish_reason" do
    error = Gemini::ChatService::ChatError.new(
      "Error message",
      status: 400,
      body: { "error" => "details" },
      finish_reason: "SAFETY"
    )

    assert_equal 400, error.status
    assert_equal({ "error" => "details" }, error.body)
    assert_equal "SAFETY", error.finish_reason
  end

  private

  def successful_response
    {
      "candidates" => [
        {
          "content" => {
            "parts" => [ { "text" => "El CGP es el Código General del Proceso..." } ],
            "role" => "model",
          },
          "finishReason" => "STOP",
          "index" => 0,
          "groundingMetadata" => {
            "groundingChunks" => [
              {
                "retrievedContext" => {
                  "title" => "Sentencia C-016-98",
                  "text" => "La Corte Constitucional ha señalado que el principio de la estabilidad en\n el empleo no se opone a la celebración de contratos a término fijo.\n\n--- PAGE 7 ---\n\nEl argumento central esgrimido por el actor parte del supuesto de que, al permitir que se pacten contratos de trabajo fijando un término de vigencia, la ley contraría el artículo 53 de la Constitución.",
                  "fileSearchStore" => "fileSearchStores/test-store-abc123",
                },
              },
              {
                "retrievedContext" => {
                  "title" => "Sentencia C-016-98",
                  "text" => "RESUELVE:\n\nPrimero.- ESTESE a lo resuelto por la Corte en relación con las palabras\n \"...pero es renovable indefinidamente\", del artículo 46 del Código Sustantivo\n del Trabajo.\n\n--- PAGE 13 ---\n\nTercero.- Declarar EXEQUIBLES, las expresiones \"por tiempo determinado\"\n del artículo 45 del Código Sustantivo del Trabajo.",
                  "fileSearchStore" => "fileSearchStores/test-store-abc123",
                },
              },
            ],
            "groundingSupports" => [
              {
                "segment" => {
                  "startIndex" => 0,
                  "endIndex" => 100,
                  "text" => "El principio de estabilidad en el empleo no se opone a la celebración de contratos a término fijo.",
                },
                "groundingChunkIndices" => [ 0 ],
                "confidenceScores" => [ 0.92 ],
              },
              {
                "segment" => {
                  "startIndex" => 101,
                  "endIndex" => 200,
                  "text" => "Declarar EXEQUIBLES las expresiones por tiempo determinado.",
                },
                "groundingChunkIndices" => [ 1 ],
                "confidenceScores" => [ 0.88 ],
              },
            ],
          },
        },
      ],
      "usageMetadata" => {
        "promptTokenCount" => 200,
        "candidatesTokenCount" => 300,
        "totalTokenCount" => 500,
        "promptTokensDetails" => [
          { "modality" => "TEXT", "tokenCount" => 200 },
        ],
      },
    }
  end

  def blocked_response(finish_reason:)
    {
      "candidates" => [
        {
          "content" => { "parts" => [ { "text" => "" } ] },
          "finishReason" => finish_reason,
          "groundingMetadata" => {},
        },
      ],
      "usageMetadata" => { "totalTokenCount" => 50 },
    }
  end
end
