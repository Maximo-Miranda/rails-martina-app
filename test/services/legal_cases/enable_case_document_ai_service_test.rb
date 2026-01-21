# frozen_string_literal: true

require "test_helper"

class LegalCases::EnableCaseDocumentAiServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @store = gemini_file_search_stores(:active_store)
    @notebook = case_notebooks(:principal_notebook)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  def build_case_document_with_file
    case_doc = CaseDocument.new(
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :memorial,
      name: "Test Document for AI",
      description: "Test description",
      folio_start: 200,
      folio_end: 210,
      page_count: 11,
      document_date: Date.current,
      issuer: "Test Issuer"
    )
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    case_doc.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
    case_doc.save!
    case_doc
  end

  test "creates Document and links to case_document" do
    case_document = build_case_document_with_file

    result = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document,
      user: @user
    )

    assert result.success?
    assert_not_nil result.document
    assert_equal result.document.id, case_document.reload.document_id
  end

  test "enqueues Documents::UploadDocumentJob for pending document" do
    case_document = build_case_document_with_file

    assert_enqueued_with(job: Documents::UploadDocumentJob) do
      LegalCases::EnableCaseDocumentAiService.call(
        case_document: case_document,
        user: @user
      )
    end
  end

  test "reuses existing document with same file_hash" do
    case_document1 = build_case_document_with_file
    result1 = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document1,
      user: @user
    )

    # Create another case_document with same file content
    case_document2 = CaseDocument.new(
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :prueba,
      name: "Another Document",
      description: "Another description",
      folio_start: 300,
      folio_end: 310,
      page_count: 11,
      document_date: Date.current,
      issuer: "Another Issuer"
    )
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    case_document2.file.attach(io: File.open(file_path), filename: "test2.txt", content_type: "text/plain")
    case_document2.save!

    result2 = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document2,
      user: @user
    )

    assert result2.success?
    # Should reuse the same Document record (deduplication)
    assert_equal result1.document.id, result2.document.id
  end

  test "returns error when file not attached" do
    case_document = CaseDocument.new(
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :memorial,
      name: "No File Doc",
      description: "Test description",
      folio_start: 100,
      folio_end: 110,
      page_count: 11,
      document_date: Date.current,
      issuer: "Test Issuer"
    )
    # Skip validation to create without file
    case_document.save!(validate: false)

    result = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document,
      user: @user
    )

    assert_not result.success?
    assert_not_nil result.error
  end

  test "returns error when store not found" do
    # Set project_id to nil on the store to simulate no store available
    @project.gemini_file_search_store.update_column(:project_id, nil)

    case_document = build_case_document_with_file

    result = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document,
      user: @user
    )

    assert_not result.success?
    assert_not_nil result.error
  end

  test "returns error when content_type unsupported" do
    case_document = CaseDocument.new(
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :memorial,
      name: "Unsupported File",
      description: "Test description",
      folio_start: 100,
      folio_end: 110,
      page_count: 11,
      document_date: Date.current,
      issuer: "Test Issuer"
    )
    # Attach unsupported file type
    case_document.file.attach(
      io: StringIO.new("test content"),
      filename: "test.xyz",
      content_type: "application/x-unsupported"
    )
    case_document.save!

    result = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document,
      user: @user
    )

    assert_not result.success?
    assert_not_nil result.error
  end

  test "builds correct metadata" do
    case_document = build_case_document_with_file

    result = LegalCases::EnableCaseDocumentAiService.call(
      case_document: case_document,
      user: @user
    )

    assert result.success?
    metadata = result.document.custom_metadata

    assert_equal "legal_case", metadata["source"]
    assert_equal case_document.legal_case.id.to_s, metadata["legal_case_id"]
    assert_equal case_document.legal_case.case_number, metadata["legal_case_number"]
    assert_equal case_document.case_notebook_id.to_s, metadata["case_notebook_id"]
    assert_equal case_document.document_type, metadata["document_type"]
    assert_equal case_document.issuer, metadata["issuer"]
  end
end
