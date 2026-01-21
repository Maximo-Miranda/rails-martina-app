# frozen_string_literal: true

require "application_system_test_case"
require "securerandom"

class DocumentsTest < ApplicationSystemTestCase
  include VcrTestHelper

  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)

    @global_store = gemini_file_search_stores(:global_store)
    @project_store = gemini_file_search_stores(:active_store)
    @project = @project_store.project
  end

  test "admin can upload document to global store and view detail" do
    with_vcr_lifecycle_cassette("system/documents_global_upload_lifecycle") do
      ensure_store_synced(@global_store)
      sign_in_with_form(@admin)
      navigate_to_global_documents
      open_global_upload_form

      display_name = "Documento global #{SecureRandom.hex(3)}"

      attach_document_file("global-documents")
      fill_in_field "[data-testid='global-documents-input-display-name'] input", with: display_name
      find("[data-testid='global-documents-btn-submit']").click

      assert_current_path(/\/documents\?.*scope=global.*store_id=#{@global_store.id}/)
      assert_text display_name

      document = Document.find_by!(display_name: display_name)
      document_id = document.id
      assert_nil document.project_id
      assert_equal @global_store.id, document.gemini_file_search_store_id
      assert_equal "pending", document.status
      assert_selector "[data-testid='document-status-#{document_id}']", text: "Pendiente"

      perform_enqueued_jobs
      document.reload
      assert_equal "active", document.status, "Error: #{document.error_message}"

      # WebSocket broadcast runs in test process, not Capybara's server - navigate to verify
      navigate_to_global_documents
      assert_selector "[data-testid='document-status-#{document_id}']", text: "Activo", wait: 5
    end
  end

  test "admin can delete document from global store" do
    document = create_document_record(
      store: @global_store,
      project: nil,
      uploader: @admin,
      status: :active,
      remote_id: "global-delete-#{SecureRandom.hex(4)}",
      gemini_document_path: "corpora/global/delete-path"
    )

    sign_in_with_form(@admin)
    navigate_to_global_documents
    assert_selector "[data-testid='global-documents-btn-delete-#{document.id}']"

    document_id = document.id
    document_name = document.display_name
    find("[data-testid='global-documents-btn-delete-#{document_id}']").click
    assert_selector "[data-testid='global-documents-delete-dialog']"
    find("[data-testid='global-documents-delete-dialog-btn-confirm']").click

    # Document should disappear from the list after deletion
    assert_no_text document_name, wait: 5
  end

  test "owner can upload document to project store" do
    with_vcr_lifecycle_cassette("system/documents_project_upload_lifecycle") do
      ensure_store_synced(@project_store)
      sign_in_with_form(@owner)
      navigate_to_project_documents
      open_project_upload_form

      document_name = "Documento proyecto #{SecureRandom.hex(3)}"

      attach_document_file("project-documents")
      fill_in_field "[data-testid='project-documents-input-display-name'] input", with: document_name
      find("[data-testid='project-documents-btn-submit']").click

      assert_selector "[data-testid='project-documents-table']"
      assert_text document_name

      document = Document.find_by!(display_name: document_name)
      document_id = document.id
      assert_equal "pending", document.status
      assert_selector "[data-testid='document-status-#{document_id}']", text: "Pendiente"

      perform_enqueued_jobs
      document.reload
      assert_equal "active", document.status

      # WebSocket broadcast runs in test process - navigate to verify
      navigate_to_project_documents
      assert_selector "[data-testid='document-status-#{document_id}']", text: "Activo", wait: 5
    end
  end

  test "coworker can delete project document" do
    document = create_document_record(
      store: @project_store,
      project: @project,
      uploader: @owner,
      status: :active,
      remote_id: "project-delete-#{SecureRandom.hex(4)}",
      gemini_document_path: "corpora/project/delete-path"
    )

    sign_in_with_form(@coworker)
    navigate_to_project_documents

    document_id = document.id
    document_name = document.display_name
    find("[data-testid='project-documents-btn-delete-#{document_id}']").click
    assert_selector "[data-testid='project-documents-delete-dialog']"
    find("[data-testid='project-documents-delete-dialog-btn-confirm']").click

    # Document should disappear from the list after deletion
    assert_no_text document_name, wait: 5
  end

  test "client can view project documents but cannot upload or delete" do
    document = create_document_record(
      store: @project_store,
      project: @project,
      uploader: @owner,
      status: :active,
      remote_id: "project-readonly-#{SecureRandom.hex(4)}",
      gemini_document_path: "corpora/project/readonly"
    )

    sign_in_with_form(@client)
    navigate_to_project_documents

    assert_selector "[data-testid='project-documents-table']"
    assert_text document.display_name
    assert_no_selector "[data-testid='project-documents-btn-upload']"
    assert_no_selector "[data-testid='project-documents-btn-delete-#{document.id}']"

    find("[data-testid='nav-hamburger']").click
    within("[data-testid='nav-drawer']") do
      assert_no_selector "[data-testid='nav-item-documents?scope=global']"
    end
  end

  private

  def fixture_file_path
    Rails.root.join("test/fixtures/files/sample-document.txt")
  end

  def attach_document_file(prefix)
    page.driver.with_playwright_page do |playwright_page|
      file_chooser = playwright_page.expect_file_chooser do
        find("[data-testid='#{prefix}-upload-zone']").click
      end
      file_chooser.set_files(fixture_file_path.to_s)
    end
  end

  def create_document_record(store:, project:, uploader:, status:, remote_id:, gemini_document_path:)
    file_path = fixture_file_path
    document = Document.new(
      display_name: "Documento #{SecureRandom.hex(3)}",
      content_type: "text/plain",
      size_bytes: File.size(file_path),
      file_hash: SecureRandom.hex(16),
      gemini_file_search_store: store,
      project: project,
      uploaded_by: uploader,
      status: status,
      remote_id: remote_id,
      gemini_document_path: gemini_document_path
    )

    file_io = StringIO.new(File.binread(file_path))
    file_io.binmode
    document.file.attach(io: file_io, filename: file_path.basename.to_s, content_type: "text/plain")

    document.save!
    document
  end

  def open_global_upload_form
    find("[data-testid='global-documents-btn-upload']").click
    assert_current_path(/scope=global/, wait: 10)
    assert_selector "form[data-testid='global-documents-form']", wait: 10
  end

  def navigate_to_global_documents
    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click
    assert_selector "[data-testid='nav-drawer']", visible: true
    # Use JS click to avoid Playwright viewport issues during drawer animation
    page.execute_script("document.querySelector(\"[data-testid='nav-item-documents?scope=global']\").click()")
    assert_selector "[data-testid='documents-store-card-#{@global_store.id}']"
    find("[data-testid='documents-store-card-#{@global_store.id}']").click
    assert_selector "[data-testid='global-documents-table']"
  end

  def navigate_to_project_documents
    assert_selector "[data-testid='nav-drawer']"
    find("[data-testid='nav-hamburger']").click
    assert_selector "[data-testid='nav-drawer']", visible: true
    # Use JS click - Playwright's force:true still checks viewport in some cases
    page.execute_script("document.querySelector(\"[data-testid='nav-item-documents']\").click()")
    assert_selector "[data-testid='project-documents-table']"
  end

  def open_project_upload_form
    find("[data-testid='project-documents-btn-upload']").click
    assert_selector "[data-testid='project-documents-form']", wait: 10
  end

  def ensure_store_synced(store)
    return if store.gemini_store_name.present? && store.gemini_store_name.start_with?("fileSearchStores/")

    store.update!(status: :pending, gemini_store_name: nil)
    Gemini::CreateStoreJob.perform_now(store.id)
    store.reload
  end
end
