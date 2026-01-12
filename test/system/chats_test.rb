# frozen_string_literal: true

require "application_system_test_case"

class ChatsTest < ApplicationSystemTestCase
  include VcrTestHelper

  setup do
    @owner = users(:confirmed_user)
    @project = projects(:test_project)
    @store = gemini_file_search_stores(:active_store)
    @test_document = nil
  end

  teardown do
    # Cleanup uploaded document if exists
    @test_document&.destroy! if @test_document&.persisted?
  end

  test "owner can create chat, send message, receive response and delete it" do
    with_vcr_lifecycle_cassette("system/chats_complete_flow") do
      ensure_store_synced(@store)

      @test_document = upload_test_document(@store)

      sign_in_with_form(@owner)

      navigate_to_chats

      assert_selector "[data-testid='chats-btn-new']", wait: 10
      find("[data-testid='chats-btn-new']").click

      assert_selector "[data-testid='chats-input-title']", wait: 10
      fill_in_field "[data-testid='chats-input-title'] input", with: "Consulta sobre CGP"

      find("[data-testid='form-btn-submit']").click

      assert_selector "[data-testid='chats-title']", text: "Consulta sobre CGP", wait: 10

      assert_selector "[data-testid='chats-connection-status']", wait: 10

      question = "¿Cuáles son los requisitos de la demanda según el artículo 82 del CGP?"
      find("[data-testid='chat-input-textarea']").fill_in with: question

      find("[data-testid='chat-btn-send']").click

      assert_selector "[data-testid^='chat-message-']", minimum: 1, wait: 10
      assert_text question, wait: 5

      perform_enqueued_jobs

      # Reload page to see the assistant response (WebSocket broadcasts don't work in tests)
      visit current_path

      # Verify we can see at least 2 messages (user + assistant)
      assert_selector "[data-testid^='chat-message-']", minimum: 2, wait: 30

      # Verify the assistant responded with relevant content
      # The response should mention aspects of article 82 (demanda)
      assert_text "demanda", wait: 10

      find("[data-testid='chats-btn-back']").click
      assert_selector "[data-testid='chats-table']", wait: 10

      assert_text "Consulta sobre CGP"

      chat_row = find("tr", text: "Consulta sobre CGP")
      chat_row.find("[data-testid='chats-btn-delete']").click
      assert_selector "[data-testid='chats-dialog-delete']", wait: 5

      find("[data-testid='chats-dialog-delete-btn-confirm']").click

      assert_no_text "Consulta sobre CGP", wait: 10
    end
  end

  private

  def navigate_to_chats
    find("[data-testid='nav-hamburger']").click
    assert_selector "[data-testid='nav-drawer']", wait: 5
    within("[data-testid='nav-drawer']") do
      find("[data-testid='nav-item-chats']").click
    end
    assert_selector "[data-testid='chats-btn-new']", wait: 10
  end

  def ensure_store_synced(store)
    return if store.gemini_store_name.present? && store.gemini_store_name.start_with?("fileSearchStores/")

    store.update!(status: :pending, gemini_store_name: nil)
    Gemini::CreateStoreJob.perform_now(store.id)
    store.reload
  end

  def upload_test_document(store)
    file_path = Rails.root.join("test/fixtures/files/ley_1564_cgp_extracto.txt")

    document = Document.new(
      display_name: "Ley 1564 CGP - Extracto",
      content_type: "text/plain",
      size_bytes: File.size(file_path),
      file_hash: SecureRandom.hex(16),
      gemini_file_search_store: store,
      project: store.project,
      uploaded_by: @owner,
      status: :pending
    )

    file_io = StringIO.new(File.binread(file_path))
    file_io.binmode
    document.file.attach(io: file_io, filename: file_path.basename.to_s, content_type: "text/plain")
    document.save!

    # Process the document with Gemini
    Documents::UploadDocumentJob.perform_now(document.id)
    document.reload

    document
  end
end
