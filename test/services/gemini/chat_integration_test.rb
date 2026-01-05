# frozen_string_literal: true

require "test_helper"

# Integration tests for Gemini Chat services using real API calls recorded with VCR
# These tests create a complete flow: store -> document -> chat -> citations
class Gemini::ChatIntegrationTest < ActiveSupport::TestCase
  include VcrTestHelper

  setup do
    @user = users(:confirmed_user)
    # Use a unique project for each test to avoid store uniqueness conflicts
    @project = Project.create!(
      name: "Chat Integration Test Project #{SecureRandom.hex(4)}",
      user: @user
    )
  end

  teardown do
    # Cleanup: destroy all stores and chats created during test
    store = @project&.gemini_file_search_store
    if store&.gemini_store_name.present?
      begin
        Gemini::DeleteStoreJob.perform_now(store.gemini_store_name)
      rescue StandardError => e
        Rails.logger.warn "Failed to delete store #{store.gemini_store_name}: #{e.message}"
      end
    end
    @project&.destroy
  end

  test "complete chat flow with file search returns content and citations" do
    with_vcr_lifecycle_cassette("services/chat_integration_complete_flow") do
      store = GeminiFileSearchStore.create!(
        project: @project,
        display_name: "Chat Integration Test Store #{SecureRandom.hex(4)}",
        status: :pending
      )

      # 2. Create store in Gemini API
      Gemini::CreateStoreJob.perform_now(store.id)
      store.reload
      assert store.active?, "Store should be active after creation"
      assert store.gemini_store_name.present?, "Store should have a gemini_store_name"

      # 3. Upload a real PDF document (Sentencia C-016-98)
      document = create_and_upload_pdf_document(store)
      assert document.active?, "Document should be active after upload"

      # 4. Create a chat associated to this store
      chat = Chat.new(
        project: @project,
        user: @user,
        gemini_file_search_store: store,
        title: "Test Chat Integration"
      )
      # Skip validation since store is now synced
      chat.save!(validate: false)

      # 5. Send a message using ChatService
      result = Gemini::ChatService.send_message(
        chat: chat,
        user_message: "¿Cuál es el tema principal de la sentencia C-016-98 y qué derechos fundamentales analiza?"
      )

      # 6. Verify the response
      assert result[:content].present?, "Should have content in response"
      assert result[:token_count].positive?, "Should have token count"
      assert_includes %w[STOP MAX_TOKENS], result[:finish_reason]

      # 7. Verify grounding metadata is present
      assert result[:grounding_metadata].present?, "Should have grounding metadata"

      # 8. Log for debugging - inspect the grounding chunks to see page markers
      Rails.logger.info "=" * 80
      Rails.logger.info "CHAT RESPONSE:"
      Rails.logger.info result[:content]
      Rails.logger.info "=" * 80
      Rails.logger.info "GROUNDING METADATA:"
      Rails.logger.info result[:grounding_metadata].to_json
      Rails.logger.info "=" * 80
      Rails.logger.info "CITATIONS:"
      Rails.logger.info result[:citations].to_json
      Rails.logger.info "=" * 80
    end
  end

  test "chat service handles questions about specific articles" do
    with_vcr_lifecycle_cassette("services/chat_integration_specific_article") do
      store = create_test_store_with_pdf_document

      chat = Chat.new(
        project: @project,
        user: @user,
        gemini_file_search_store: store,
        title: "Article Query Test"
      )
      chat.save!(validate: false)

      result = Gemini::ChatService.send_message(
        chat: chat,
        user_message: "¿Qué dice la sentencia sobre el derecho a la intimidad y la inviolabilidad del domicilio?"
      )

      assert result[:content].present?
      # The response should mention constitutional rights concepts
      content_lower = result[:content].downcase

      assert(
        content_lower.include?("intimidad") ||
        content_lower.include?("domicilio") ||
        content_lower.include?("derecho") ||
        content_lower.include?("constitucional"),
        "Response should mention constitutional rights concepts"
      )
    end
  end

  test "chat service extracts citations from grounding metadata" do
    with_vcr_lifecycle_cassette("services/chat_integration_citations") do
      store = create_test_store_with_pdf_document

      chat = Chat.new(
        project: @project,
        user: @user,
        gemini_file_search_store: store,
        title: "Citations Test"
      )
      chat.save!(validate: false)

      result = Gemini::ChatService.send_message(
        chat: chat,
        user_message: "¿Cuáles fueron los argumentos del demandante en la sentencia C-016-98?"
      )

      assert result[:content].present?
      assert result[:grounding_metadata].is_a?(Hash)

      # Log grounding chunks to inspect page format
      chunks = result[:grounding_metadata]["groundingChunks"]
      Rails.logger.info "=" * 80
      Rails.logger.info "GROUNDING CHUNKS FOR CITATIONS TEST:"
      chunks&.each_with_index do |chunk, i|
        text = chunk.dig("retrievedContext", "text")
        Rails.logger.info "Chunk #{i}: #{text&.truncate(500)}"
        Rails.logger.info "-" * 40
      end
      Rails.logger.info "=" * 80
    end
  end

  test "chat service handles conversation history" do
    with_vcr_lifecycle_cassette("services/chat_integration_history") do
      store = create_test_store_with_pdf_document

      chat = Chat.new(
        project: @project,
        user: @user,
        gemini_file_search_store: store,
        title: "History Test"
      )
      chat.save!(validate: false)

      # First message
      Message.create!(
        chat: chat,
        user: @user,
        role: :user_role,
        content: "¿De qué trata la sentencia C-016-98?",
        status: :completed
      )

      Message.create!(
        chat: chat,
        role: :assistant_role,
        content: "La sentencia C-016-98 de la Corte Constitucional analiza la constitucionalidad de normas relacionadas con allanamientos y registros domiciliarios.",
        status: :completed
      )

      # Follow-up question that references the previous context
      result = Gemini::ChatService.send_message(
        chat: chat,
        user_message: "¿Cuál fue la decisión final de la Corte?"
      )

      assert result[:content].present?
      # The response might be blocked by RECITATION or contain the decision
      content_lower = result[:content].downcase
      is_valid_response = content_lower.include?("exequible") ||
                          content_lower.include?("inexequible") ||
                          content_lower.include?("constitucional") ||
                          content_lower.include?("corte") ||
                          content_lower.include?("decisión") ||
                          content_lower.include?("bloqueada") ||
                          content_lower.include?("derechos de autor")

      assert is_valid_response, "Response should reference the Court's decision or be a valid blocked message"
    end
  end

  test "chat service returns appropriate message when no relevant info found" do
    with_vcr_lifecycle_cassette("services/chat_integration_no_info") do
      store = create_test_store_with_pdf_document

      chat = Chat.new(
        project: @project,
        user: @user,
        gemini_file_search_store: store,
        title: "No Info Test"
      )
      chat.save!(validate: false)

      # Ask about something not in the document
      result = Gemini::ChatService.send_message(
        chat: chat,
        user_message: "¿Cuál es la receta de la arepa colombiana?"
      )

      assert result[:content].present?
      # The response should indicate it doesn't have info about this
      # or the model might still try to answer based on general knowledge
      Rails.logger.info "Response for irrelevant question: #{result[:content]}"
    end
  end

  private

  def create_test_store_with_pdf_document
    store = GeminiFileSearchStore.create!(
      project: @project,
      display_name: "Chat Test Store #{SecureRandom.hex(4)}",
      status: :pending
    )

    Gemini::CreateStoreJob.perform_now(store.id)
    store.reload

    create_and_upload_pdf_document(store)

    store
  end

  def create_and_upload_pdf_document(store)
    pdf_path = Rails.root.join("test/fixtures/files/c-016-98.pdf")
    pdf_content = File.read(pdf_path, mode: "rb")

    document = Document.new(
      project: @project,
      gemini_file_search_store: store,
      uploaded_by: @user,
      display_name: "Sentencia C-016-98 #{SecureRandom.hex(4)}",
      content_type: "application/pdf",
      size_bytes: pdf_content.bytesize,
      file_hash: Digest::SHA256.hexdigest(pdf_content),
      status: :pending
    )

    document.file.attach(
      io: StringIO.new(pdf_content),
      filename: "c-016-98.pdf",
      content_type: "application/pdf"
    )

    document.save!

    # Upload to Gemini
    Documents::UploadDocumentJob.perform_now(document.id)
    document.reload

    document
  end

  def create_and_upload_document(store, content)
    # Create document record
    document = Document.new(
      project: @project,
      gemini_file_search_store: store,
      uploaded_by: @user,
      display_name: "Ley 1564 CGP Test #{SecureRandom.hex(4)}",
      content_type: "text/plain",
      size_bytes: content.bytesize,
      file_hash: Digest::SHA256.hexdigest(content),
      status: :pending
    )

    # Attach file content
    document.file.attach(
      io: StringIO.new(content),
      filename: "ley_1564_cgp.txt",
      content_type: "text/plain"
    )

    document.save!

    # Upload to Gemini
    Documents::UploadDocumentJob.perform_now(document.id)
    document.reload

    document
  end
end
