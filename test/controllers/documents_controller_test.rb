# frozen_string_literal: true

require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
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

    @global_document = create_document(store: @global_store, project: nil)
    @project_document = create_document(store: @project_store, project: @project)
  end

  # === Global Documents: Unauthorized Access ===

  test "owner cannot access global documents index" do
    sign_in @owner
    get documents_path(scope: "global", store_id: @global_store.id)
    assert_redirected_to dashboard_path
    assert flash[:alert].present?
  end

  test "coworker cannot access global documents index" do
    sign_in @coworker
    get documents_path(scope: "global", store_id: @global_store.id)
    assert_redirected_to dashboard_path
    assert flash[:alert].present?
  end

  test "client cannot access global documents index" do
    sign_in @client
    get documents_path(scope: "global", store_id: @global_store.id)
    assert_redirected_to dashboard_path
    assert flash[:alert].present?
  end

  test "owner cannot create global document" do
    sign_in @owner
    post documents_path(scope: "global", store_id: @global_store.id), params: {
      document: { display_name: "Hack", file: fixture_file_upload("sample-document.txt", "text/plain") },
    }
    assert_redirected_to dashboard_path
    assert flash[:alert].present?
  end

  test "owner cannot delete global document" do
    sign_in @owner
    delete document_path(@global_document, scope: "global")
    assert_redirected_to dashboard_path
    assert flash[:alert].present?
  end

  # === Global Documents: Authorized Access ===

  test "admin can access global documents index" do
    sign_in @admin
    get documents_path(scope: "global", store_id: @global_store.id)
    assert_response :success
  end

  test "super_admin can access global documents index" do
    sign_in @super_admin
    get documents_path(scope: "global", store_id: @global_store.id)
    assert_response :success
  end

  # === Project Documents: Unauthorized Access ===

  test "outsider cannot access project documents" do
    sign_in @outsider
    ActsAsTenant.with_tenant(@project) do
      get documents_path(store_id: @project_store.id)
    end
    assert_response :redirect
  end

  test "outsider cannot create project document" do
    sign_in @outsider
    ActsAsTenant.with_tenant(@project) do
      post documents_path(store_id: @project_store.id), params: {
        document: { display_name: "Hack", file: fixture_file_upload("sample-document.txt", "text/plain") },
      }
    end
    assert_response :redirect
  end

  test "outsider cannot delete project document" do
    sign_in @outsider
    ActsAsTenant.with_tenant(@project) do
      delete document_path(@project_document)
    end
    # Document not found in outsider's scope → 404
    assert_response :not_found
  end

  test "client cannot create project document" do
    sign_in @client
    ActsAsTenant.with_tenant(@project) do
      post documents_path(store_id: @project_store.id), params: {
        document: { display_name: "Hack", file: fixture_file_upload("sample-document.txt", "text/plain") },
      }
    end
    assert_redirected_to dashboard_path
  end

  test "client cannot delete project document" do
    sign_in @client
    ActsAsTenant.with_tenant(@project) do
      delete document_path(@project_document)
    end
    assert_redirected_to dashboard_path
  end

  # === Project Documents: Authorized Access ===

  test "owner can access project documents index" do
    sign_in @owner
    ActsAsTenant.with_tenant(@project) do
      get documents_path(store_id: @project_store.id)
    end
    assert_response :success
  end

  test "coworker can access project documents index" do
    sign_in @coworker
    ActsAsTenant.with_tenant(@project) do
      get documents_path(store_id: @project_store.id)
    end
    assert_response :success
  end

  test "client can access project documents index (read-only)" do
    sign_in @client
    ActsAsTenant.with_tenant(@project) do
      get documents_path(store_id: @project_store.id)
    end
    assert_response :success
  end

  # === Unauthenticated Access ===

  test "unauthenticated user is redirected from global documents" do
    get documents_path(scope: "global", store_id: @global_store.id)
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated user is redirected from project documents" do
    get documents_path(store_id: @project_store.id)
    assert_redirected_to new_user_session_path
  end

  private

  def create_document(store:, project:)
    file_path = Rails.root.join("test/fixtures/files/sample-document.txt")
    document = Document.new(
      display_name: "Test Doc #{SecureRandom.hex(3)}",
      content_type: "text/plain",
      size_bytes: File.size(file_path),
      file_hash: SecureRandom.hex(16),
      gemini_file_search_store: store,
      project: project,
      uploaded_by: @admin,
      status: :active,
      remote_id: "test-#{SecureRandom.hex(4)}",
      gemini_document_path: "corpora/test/path"
    )
    document.file.attach(io: File.open(file_path), filename: "test.txt", content_type: "text/plain")
    document.save!
    document
  end
end
