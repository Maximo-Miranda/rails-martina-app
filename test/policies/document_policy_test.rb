# frozen_string_literal: true

require "test_helper"

class DocumentPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @global_store = gemini_file_search_stores(:global_store)
    @project_store = gemini_file_search_stores(:active_store)

    @global_document = build_document(store: @global_store, project: nil)
    @project_document = build_document(store: @project_store, project: @project)
  end

  # === Global Documents (project_id = nil) ===

  test "index? global: super_admin can access" do
    assert DocumentPolicy.new(@super_admin, @global_document).index?
  end

  test "index? global: admin can access" do
    assert DocumentPolicy.new(@admin, @global_document).index?
  end

  test "index? global: owner cannot access" do
    refute DocumentPolicy.new(@owner, @global_document).index?
  end

  test "index? global: coworker cannot access" do
    refute DocumentPolicy.new(@coworker, @global_document).index?
  end

  test "index? global: client cannot access" do
    refute DocumentPolicy.new(@client, @global_document).index?
  end

  test "create? global: super_admin can create" do
    assert DocumentPolicy.new(@super_admin, @global_document).create?
  end

  test "create? global: admin can create" do
    assert DocumentPolicy.new(@admin, @global_document).create?
  end

  test "create? global: owner cannot create" do
    refute DocumentPolicy.new(@owner, @global_document).create?
  end

  test "destroy? global: super_admin can destroy" do
    assert DocumentPolicy.new(@super_admin, @global_document).destroy?
  end

  test "destroy? global: admin can destroy" do
    assert DocumentPolicy.new(@admin, @global_document).destroy?
  end

  test "destroy? global: owner cannot destroy" do
    refute DocumentPolicy.new(@owner, @global_document).destroy?
  end

  # === Project Documents ===

  test "index? project: super_admin can access" do
    assert DocumentPolicy.new(@super_admin, @project_document).index?
  end

  test "index? project: admin can access" do
    assert DocumentPolicy.new(@admin, @project_document).index?
  end

  test "index? project: owner can access own project" do
    assert DocumentPolicy.new(@owner, @project_document).index?
  end

  test "index? project: coworker can access project" do
    assert DocumentPolicy.new(@coworker, @project_document).index?
  end

  test "index? project: client can access project (read-only)" do
    assert DocumentPolicy.new(@client, @project_document).index?
  end

  test "index? project: other_user cannot access" do
    refute DocumentPolicy.new(@outsider, @project_document).index?
  end

  test "create? project: super_admin can create" do
    assert DocumentPolicy.new(@super_admin, @project_document).create?
  end

  test "create? project: admin can create" do
    assert DocumentPolicy.new(@admin, @project_document).create?
  end

  test "create? project: owner can create in own project" do
    assert DocumentPolicy.new(@owner, @project_document).create?
  end

  test "create? project: coworker can create" do
    assert DocumentPolicy.new(@coworker, @project_document).create?
  end

  test "create? project: client cannot create (read-only)" do
    refute DocumentPolicy.new(@client, @project_document).create?
  end

  test "create? project: other_user cannot create" do
    refute DocumentPolicy.new(@outsider, @project_document).create?
  end

  test "destroy? project: super_admin can destroy" do
    assert DocumentPolicy.new(@super_admin, @project_document).destroy?
  end

  test "destroy? project: admin can destroy" do
    assert DocumentPolicy.new(@admin, @project_document).destroy?
  end

  test "destroy? project: owner can destroy in own project" do
    assert DocumentPolicy.new(@owner, @project_document).destroy?
  end

  test "destroy? project: coworker can destroy" do
    assert DocumentPolicy.new(@coworker, @project_document).destroy?
  end

  test "destroy? project: client cannot destroy (read-only)" do
    refute DocumentPolicy.new(@client, @project_document).destroy?
  end

  # === Class Methods ===

  test "show_menu? returns true for super_admin" do
    assert DocumentPolicy.show_menu?(@super_admin)
  end

  test "show_menu? returns true for admin" do
    assert DocumentPolicy.show_menu?(@admin)
  end

  test "show_menu? returns false for owner" do
    refute DocumentPolicy.show_menu?(@owner)
  end

  test "show_menu? returns false for nil user" do
    refute DocumentPolicy.show_menu?(nil)
  end

  test "show_project_menu? returns true for super_admin" do
    assert DocumentPolicy.show_project_menu?(@super_admin, @project)
  end

  test "show_project_menu? returns true for admin" do
    assert DocumentPolicy.show_project_menu?(@admin, @project)
  end

  test "show_project_menu? returns true for owner of project" do
    assert DocumentPolicy.show_project_menu?(@owner, @project)
  end

  test "show_project_menu? returns true for coworker of project" do
    assert DocumentPolicy.show_project_menu?(@coworker, @project)
  end

  test "show_project_menu? returns true for client of project" do
    assert DocumentPolicy.show_project_menu?(@client, @project)
  end

  test "show_project_menu? returns false for other_user" do
    refute DocumentPolicy.show_project_menu?(@outsider, @project)
  end

  test "show_project_menu? returns false for nil user" do
    refute DocumentPolicy.show_project_menu?(nil, @project)
  end

  test "show_project_menu? returns false for nil project" do
    refute DocumentPolicy.show_project_menu?(@owner, nil)
  end

  # === Scope ===

  test "scope: super_admin sees all documents" do
    create_documents_for_scope_test
    scope = DocumentPolicy::Scope.new(@super_admin, Document).resolve
    assert_equal Document.count, scope.count
  end

  test "scope: admin sees all documents" do
    create_documents_for_scope_test
    scope = DocumentPolicy::Scope.new(@admin, Document).resolve
    assert_equal Document.count, scope.count
  end

  test "scope: owner sees only accessible project documents" do
    global_doc, project_doc = create_documents_for_scope_test
    scope = DocumentPolicy::Scope.new(@owner, Document).resolve

    refute_includes scope, global_doc
    assert_includes scope, project_doc
  end

  test "scope: other_user sees no documents" do
    create_documents_for_scope_test
    scope = DocumentPolicy::Scope.new(@outsider, Document).resolve
    assert_empty scope
  end

  private

  def build_document(store:, project:)
    Document.new(
      display_name: "Test Document",
      content_type: "text/plain",
      size_bytes: 100,
      file_hash: SecureRandom.hex(16),
      gemini_file_search_store: store,
      project: project,
      uploaded_by: @admin,
      status: :active
    )
  end

  def create_documents_for_scope_test
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")

    global_doc = Document.new(
      display_name: "Global Doc",
      content_type: "text/plain",
      size_bytes: File.size(file_path),
      file_hash: SecureRandom.hex(16),
      gemini_file_search_store: @global_store,
      project: nil,
      uploaded_by: @admin,
      status: :active,
      remote_id: "scope-test-global",
      gemini_document_path: "corpora/scope/global"
    )
    global_doc.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
    global_doc.save!

    project_doc = Document.new(
      display_name: "Project Doc",
      content_type: "text/plain",
      size_bytes: File.size(file_path),
      file_hash: SecureRandom.hex(16),
      gemini_file_search_store: @project_store,
      project: @project,
      uploaded_by: @owner,
      status: :active,
      remote_id: "scope-test-project",
      gemini_document_path: "corpora/scope/project"
    )
    project_doc.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
    project_doc.save!

    [ global_doc, project_doc ]
  end
end
