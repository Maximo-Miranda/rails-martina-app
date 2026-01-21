# frozen_string_literal: true

require "test_helper"

class LegalCases::DisableCaseDocumentAiServiceTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @notebook = case_notebooks(:principal_notebook)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  def build_case_document_with_ai_enabled
    case_doc = CaseDocument.new(
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :memorial,
      name: "AI Enabled Document",
      description: "Test description",
      folio_start: 400,
      folio_end: 410,
      page_count: 11,
      document_date: Date.current,
      issuer: "Test Issuer"
    )
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    case_doc.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
    case_doc.save!

    # Create an AI Document for this test
    store = gemini_file_search_stores(:active_store)
    ai_document = Document.new(
      gemini_file_search_store: store,
      uploaded_by: @user,
      project: @project,
      display_name: "AI Test Doc Disable",
      content_type: "text/plain",
      size_bytes: 100,
      file_hash: SecureRandom.hex(16),
      status: :active,
      remote_id: "test-remote-#{SecureRandom.hex(4)}"
    )
    ai_document.file.attach(io: File.open(file_path), filename: "ai-test.txt", content_type: "text/plain")
    ai_document.save!

    case_doc.update_column(:document_id, ai_document.id)
    case_doc
  end

  test "removes document_id from case_document and discards Document" do
    case_document = build_case_document_with_ai_enabled
    ai_document = case_document.document

    assert case_document.ai_enabled?

    result = LegalCases::DisableCaseDocumentAiService.call(case_document: case_document)

    assert result.success?
    assert_nil case_document.reload.document_id
    assert ai_document.reload.discarded?
  end

  test "returns error when AI not enabled" do
    case_document = CaseDocument.new(
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :memorial,
      name: "No AI Document",
      description: "Test description",
      folio_start: 500,
      folio_end: 510,
      page_count: 11,
      document_date: Date.current,
      issuer: "Test Issuer"
    )
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    case_document.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
    case_document.save!

    assert_not case_document.ai_enabled?

    result = LegalCases::DisableCaseDocumentAiService.call(case_document: case_document)

    assert_not result.success?
    assert_not_nil result.error
  end

  test "returns success result" do
    case_document = build_case_document_with_ai_enabled

    result = LegalCases::DisableCaseDocumentAiService.call(case_document: case_document)

    assert result.success?
    assert_nil result.error
  end
end
