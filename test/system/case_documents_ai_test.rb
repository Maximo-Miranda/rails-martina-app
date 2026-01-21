# frozen_string_literal: true

require "application_system_test_case"
require "securerandom"

class CaseDocumentsAiTest < ApplicationSystemTestCase
  include VcrTestHelper

  setup do
    @owner = users(:confirmed_user)
    @project = projects(:test_project)
    @store = gemini_file_search_stores(:active_store)
    @legal_case = legal_cases(:legal_case_one)
    @notebook = case_notebooks(:principal_notebook)
    @existing_document = case_documents(:auto_admisorio)
    attach_test_file(@existing_document)
  end

  teardown do
    @test_document&.destroy! if @test_document&.persisted?
  end

  test "owner can create document from form and enable AI" do
    with_vcr_lifecycle_cassette("system/case_documents_ai_create_and_enable") do
      ensure_store_synced(@store)
      sign_in_with_form(@owner)

      navigate_to_legal_case(@legal_case)

      find("[data-testid='legal-case-tab-notebooks']").click
      assert_selector "[data-testid='legal-case-notebook-#{@notebook.id}']", wait: 5

      find("[data-testid='legal-case-notebook-#{@notebook.id}']").click
      assert_selector "[data-testid='case-notebook-btn-add-document']", wait: 5

      find("[data-testid='case-notebook-btn-add-document']").click
      assert_selector "[data-testid='case-document-input-file']", wait: 5

      attach_document_file("case-document-input-file")

      fill_in_field "[data-testid='case-document-input-name'] input", with: "Documento de Prueba AI"

      find("[data-testid='case-document-input-type']").click
      find(".v-list-item", text: /Demanda/i).click

      fill_in_field "[data-testid='case-document-input-description'] textarea", with: "Descripción del documento de prueba"
      fill_in_field "[data-testid='case-document-input-folio-start'] input", with: "1"
      fill_in_field "[data-testid='case-document-input-folio-end'] input", with: "10"
      fill_in_field "[data-testid='case-document-input-page-count'] input", with: "10"
      fill_in_field "[data-testid='case-document-input-date'] input", with: Date.current.strftime("%Y-%m-%d")
      fill_in_field "[data-testid='case-document-input-issuer'] input", with: "Juzgado de Prueba"

      find("[data-testid='case-document-btn-submit']").click

      assert_no_selector "[data-testid='case-document-btn-submit']", wait: 10

      @notebook.reload
      @test_document = @notebook.case_documents.find_by(name: "Documento de Prueba AI")
      assert_not_nil @test_document, "Document should be created"

      find("[data-testid='case-document-row-#{@test_document.id}']").click
      assert_selector "[data-testid='case-document-btn-toggle-ai']", wait: 10

      assert_not @test_document.reload.ai_enabled?, "AI should not be enabled initially"

      find("[data-testid='case-document-btn-toggle-ai']").click

      assert_selector "[data-testid='case-document-btn-toggle-ai']", text: /Deshabilitar IA/i, wait: 10

      @test_document.reload
      assert @test_document.ai_enabled?, "AI should be enabled after clicking toggle"

      perform_enqueued_jobs

      @test_document.reload
      assert @test_document.document.present?, "Document should be associated after AI enable"
      assert_equal "active", @test_document.document.status, "Document should be active after job completion"
    end
  end

  test "owner can toggle AI for existing case document" do
    with_vcr_lifecycle_cassette("system/case_documents_ai_enable_lifecycle") do
      ensure_store_synced(@store)
      sign_in_with_form(@owner)

      navigate_to_document(@legal_case, @notebook, @existing_document)

      assert_not @existing_document.reload.ai_enabled?, "AI should not be enabled initially"

      assert_selector "[data-testid='case-document-btn-toggle-ai']", wait: 10
      find("[data-testid='case-document-btn-toggle-ai']").click

      assert_selector "[data-testid='case-document-btn-toggle-ai']", text: /Deshabilitar IA/i, wait: 10

      @existing_document.reload
      assert @existing_document.ai_enabled?, "AI should be enabled after clicking toggle"

      perform_enqueued_jobs

      @existing_document.reload

      assert @existing_document.document.present?, "Document should be associated after AI enable"
      assert_equal "active", @existing_document.document.status, "Document should be active after job completion"
    end
  end

  private

  def navigate_to_legal_case(legal_case)
    find("[data-testid='nav-hamburger']").click
    assert_selector "[data-testid='nav-drawer']", wait: 5
    within("[data-testid='nav-drawer']") do
      find("[data-testid='nav-item-legal_cases']").click
    end
    assert_selector "[data-testid='legal-cases-btn-new']", wait: 10

    find("[data-testid='legal-cases-btn-view-#{legal_case.id}']").click
    assert_selector "[data-testid='legal-case-tab-info']", wait: 10
  end

  def navigate_to_document(legal_case, notebook, document)
    visit "/legal_cases/#{legal_case.id}/case_notebooks/#{notebook.id}/case_documents/#{document.id}"
    assert_selector "[data-testid='case-document-btn-toggle-ai']", wait: 10
  end

  def fill_in_field(selector, with:)
    find(selector).fill_in with: with
  end

  def attach_document_file(testid)
    page.driver.with_playwright_page do |playwright_page|
      file_chooser = playwright_page.expect_file_chooser do
        playwright_page.locator("[data-testid='#{testid}']").click
      end
      file_chooser.set_files(fixture_file_path.to_s)
    end
  end

  def fixture_file_path
    Rails.root.join("test/fixtures/files/sample-document.txt")
  end

  def ensure_store_synced(store)
    return if store.gemini_store_name.present? && store.gemini_store_name.start_with?("fileSearchStores/")

    store.update!(status: :pending, gemini_store_name: nil)
    Gemini::CreateStoreJob.perform_now(store.id)
    store.reload
  end

  def attach_test_file(document)
    return if document.file.attached?

    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    document.file.attach(
      io: File.open(file_path),
      filename: "test-document.txt",
      content_type: "text/plain"
    )
    document.save!(validate: false)
  end
end
