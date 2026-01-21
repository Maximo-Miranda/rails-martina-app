# frozen_string_literal: true

require "test_helper"

class CaseDocumentTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @notebook = case_notebooks(:principal_notebook)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  def build_case_document(attributes = {})
    defaults = {
      case_notebook: @notebook,
      uploaded_by: @user,
      document_type: :memorial,
      name: "Test Document",
      description: "Test description",
      folio_start: 100,
      folio_end: 110,
      page_count: 11,
      document_date: Date.current,
      issuer: "Test Issuer",
    }
    CaseDocument.new(defaults.merge(attributes))
  end

  def attach_test_file(document)
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    document.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
  end

  test "valid case document with file" do
    document = build_case_document
    attach_test_file(document)

    assert document.valid?
  end

  test "requires document_type" do
    document = build_case_document(document_type: nil)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :document_type
  end

  test "requires name" do
    document = build_case_document(name: nil)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :name
  end

  test "requires description" do
    document = build_case_document(description: nil)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :description
  end

  test "requires folio_start greater than 0" do
    document = build_case_document(folio_start: 0)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :folio_start
  end

  test "requires folio_end greater than or equal to folio_start" do
    document = build_case_document(folio_start: 10, folio_end: 5)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :folio_end
  end

  test "requires page_count greater than 0" do
    document = build_case_document(page_count: 0)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :page_count
  end

  test "requires document_date" do
    document = build_case_document(document_date: nil)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :document_date
  end

  test "requires issuer" do
    document = build_case_document(issuer: nil)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :issuer
  end

  test "requires file on create" do
    document = build_case_document

    assert document.invalid?
    assert_includes document.errors.attribute_names, :file
  end

  test "validates item_number uniqueness within notebook for kept records" do
    existing = case_documents(:demanda_document)
    document = build_case_document(item_number: existing.item_number)
    attach_test_file(document)

    assert document.invalid?
    assert_includes document.errors.attribute_names, :item_number
  end

  test "allows same item_number in different notebook" do
    other_notebook = case_notebooks(:medidas_notebook)
    existing = case_documents(:demanda_document)
    document = build_case_document(
      case_notebook: other_notebook,
      item_number: existing.item_number
    )
    attach_test_file(document)

    assert document.valid?
  end

  test "assign_next_item_number sets sequential number" do
    document = build_case_document
    attach_test_file(document)
    document.save!

    max_item = @notebook.case_documents.kept.where.not(id: document.id).maximum(:item_number) || 0
    assert_equal max_item + 1, document.item_number
  end

  test "assign_next_item_number skips if already set" do
    document = build_case_document(item_number: 999)
    attach_test_file(document)
    document.save!

    assert_equal 999, document.item_number
  end

  test "update_notebook_folio_count after save" do
    notebook = case_notebooks(:medidas_notebook)
    notebook.update!(folio_count: 0)

    document = build_case_document(case_notebook: notebook, page_count: 5)
    attach_test_file(document)
    document.save!

    assert_equal 5, notebook.reload.folio_count
  end

  test "discard_ai_document discards associated document on discard" do
    document = build_case_document
    attach_test_file(document)
    document.save!

    # Create an AI document for this test
    store = gemini_file_search_stores(:active_store)
    ai_document = Document.new(
      gemini_file_search_store: store,
      uploaded_by: @user,
      project: @project,
      display_name: "AI Test Doc",
      content_type: "text/plain",
      size_bytes: 100,
      file_hash: SecureRandom.hex(16),
      status: :active,
      remote_id: "test-remote-#{SecureRandom.hex(4)}"
    )
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    ai_document.file.attach(io: File.open(file_path), filename: "ai-test.txt", content_type: "text/plain")
    ai_document.save!

    document.update_column(:document_id, ai_document.id)

    document.discard

    assert ai_document.reload.discarded?
  end

  test "scope ordered returns documents by item_number" do
    documents = @notebook.case_documents.ordered

    assert_equal documents.map(&:item_number), documents.map(&:item_number).sort
  end

  test "scope with_ai returns documents with document_id" do
    document = build_case_document
    attach_test_file(document)
    document.save!

    # Create an AI document for this test
    store = gemini_file_search_stores(:active_store)
    ai_document = Document.new(
      gemini_file_search_store: store,
      uploaded_by: @user,
      project: @project,
      display_name: "AI Test Doc 2",
      content_type: "text/plain",
      size_bytes: 100,
      file_hash: SecureRandom.hex(16),
      status: :active,
      remote_id: "test-remote-#{SecureRandom.hex(4)}"
    )
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    ai_document.file.attach(io: File.open(file_path), filename: "ai-test2.txt", content_type: "text/plain")
    ai_document.save!

    document.update_column(:document_id, ai_document.id)

    assert_includes CaseDocument.with_ai, document
  end

  test "ai_enabled? returns true when document present" do
    document = build_case_document
    document.document = documents(:ley_1564_2012)

    assert document.ai_enabled?
  end

  test "ai_enabled? returns false when document nil" do
    document = build_case_document

    assert_not document.ai_enabled?
  end

  test "foliation returns single folio when start equals end" do
    document = build_case_document(folio_start: 10, folio_end: 10)

    assert_equal "10", document.foliation
  end

  test "foliation returns range when start differs from end" do
    document = build_case_document(folio_start: 10, folio_end: 20)

    assert_equal "10-20", document.foliation
  end

  test "foliation returns nil when folios not set" do
    document = CaseDocument.new

    assert_nil document.foliation
  end
end
