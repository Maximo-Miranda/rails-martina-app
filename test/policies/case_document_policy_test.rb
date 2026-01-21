# frozen_string_literal: true

require "test_helper"

class CaseDocumentPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:super_admin_user)
    @admin = users(:admin_user)
    @owner = users(:confirmed_user)
    @coworker = users(:coworker_user)
    @client = users(:client_user)
    @outsider = users(:outsider_user)

    @project = projects(:test_project)
    @case_document = case_documents(:demanda_document)
  end

  # === Index ===

  test "super_admin can index case documents" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@super_admin, CaseDocument).index?
    end
  end

  test "owner can index case documents" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, CaseDocument).index?
    end
  end

  test "coworker can index case documents" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, CaseDocument).index?
    end
  end

  test "client cannot index case documents" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, CaseDocument).index?
    end
  end

  test "outsider cannot index case documents" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@outsider, CaseDocument).index?
    end
  end

  # === Show ===

  test "owner can show case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, @case_document).show?
    end
  end

  test "coworker can show case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, @case_document).show?
    end
  end

  test "client cannot show case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, @case_document).show?
    end
  end

  # === Create ===

  test "owner can create case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, CaseDocument.new).create?
    end
  end

  test "coworker can create case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, CaseDocument.new).create?
    end
  end

  test "client cannot create case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, CaseDocument.new).create?
    end
  end

  test "outsider cannot create case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@outsider, CaseDocument.new).create?
    end
  end

  # === Update ===

  test "owner can update case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, @case_document).update?
    end
  end

  test "coworker can update case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, @case_document).update?
    end
  end

  test "client cannot update case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, @case_document).update?
    end
  end

  # === Destroy ===

  test "owner can destroy case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, @case_document).destroy?
    end
  end

  test "coworker can destroy case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, @case_document).destroy?
    end
  end

  test "client cannot destroy case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, @case_document).destroy?
    end
  end

  # === Enable AI ===

  test "owner can enable AI on case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, @case_document).enable_ai?
    end
  end

  test "coworker can enable AI on case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, @case_document).enable_ai?
    end
  end

  test "client cannot enable AI on case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, @case_document).enable_ai?
    end
  end

  # === Disable AI ===

  test "owner can disable AI on case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, @case_document).disable_ai?
    end
  end

  test "coworker can disable AI on case document" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, @case_document).disable_ai?
    end
  end

  test "client cannot disable AI on case document" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, @case_document).disable_ai?
    end
  end

  # === File URL ===

  test "owner can access file_url" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@owner, @case_document).file_url?
    end
  end

  test "coworker can access file_url" do
    ActsAsTenant.with_tenant(@project) do
      assert CaseDocumentPolicy.new(@coworker, @case_document).file_url?
    end
  end

  test "client cannot access file_url" do
    ActsAsTenant.with_tenant(@project) do
      assert_not CaseDocumentPolicy.new(@client, @case_document).file_url?
    end
  end

  # === Scope ===

  test "scope returns kept records" do
    ActsAsTenant.with_tenant(@project) do
      scope = CaseDocumentPolicy::Scope.new(@owner, CaseDocument).resolve

      assert scope.all?(&:kept?)
    end
  end
end
