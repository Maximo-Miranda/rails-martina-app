# frozen_string_literal: true

require "test_helper"

class CaseNotebookTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @legal_case = legal_cases(:legal_case_one)
    @notebook = case_notebooks(:principal_notebook)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "valid case notebook" do
    notebook = CaseNotebook.new(
      legal_case: @legal_case,
      notebook_type: :incidentes,
      code: "C03",
      description: "Cuaderno de Incidentes",
      volume: 1
    )

    assert notebook.valid?
  end

  test "requires notebook_type" do
    notebook = CaseNotebook.new(legal_case: @legal_case, code: "C99")

    assert notebook.invalid?
    assert_includes notebook.errors.attribute_names, :notebook_type
  end

  test "requires code" do
    notebook = CaseNotebook.new(legal_case: @legal_case, notebook_type: :principal)

    assert notebook.invalid?
    assert_includes notebook.errors.attribute_names, :code
  end

  test "validates code uniqueness within legal_case and volume" do
    duplicate = CaseNotebook.new(
      legal_case: @legal_case,
      notebook_type: :otro,
      code: @notebook.code,
      volume: @notebook.volume
    )

    assert duplicate.invalid?
    assert_includes duplicate.errors.attribute_names, :code
  end

  test "allows same code in different legal_case" do
    # Use the medidas_notebook (code C02) since principal (C01) is auto-created
    medidas_notebook = case_notebooks(:medidas_notebook)
    other_case = legal_cases(:legal_case_two)

    # Verify code C02 doesn't exist in other_case yet
    assert_not other_case.case_notebooks.exists?(code: medidas_notebook.code, volume: 1)

    notebook = CaseNotebook.new(
      legal_case: other_case,
      notebook_type: :medidas_cautelares,
      code: medidas_notebook.code,
      volume: 1
    )

    assert notebook.valid?
  end

  test "allows same code with different volume" do
    notebook = CaseNotebook.new(
      legal_case: @legal_case,
      notebook_type: :principal,
      code: @notebook.code,
      volume: 2
    )

    assert notebook.valid?
  end

  test "validates volume greater than 0" do
    notebook = CaseNotebook.new(
      legal_case: @legal_case,
      notebook_type: :incidentes,
      code: "C99",
      volume: 0
    )

    assert notebook.invalid?
    assert_includes notebook.errors.attribute_names, :volume
  end

  test "scope ordered returns notebooks by code and volume" do
    notebooks = @legal_case.case_notebooks.ordered

    assert_equal notebooks, notebooks.sort_by { |n| [ n.code, n.volume ] }
  end

  test "display_name returns code and type for volume 1" do
    notebook = CaseNotebook.new(
      notebook_type: :principal,
      code: "C01",
      volume: 1
    )

    assert_equal "C01 - Principal", notebook.display_name
  end

  test "display_name includes tomo for volume greater than 1" do
    notebook = CaseNotebook.new(
      notebook_type: :principal,
      code: "C01",
      volume: 2
    )

    assert_equal "C01 - Principal (Tomo 2)", notebook.display_name
  end

  test "recalculate_folio_count! sums page_count of kept documents" do
    notebook = case_notebooks(:principal_notebook)
    expected_count = notebook.case_documents.kept.sum(&:page_count)

    notebook.update!(folio_count: 0)
    notebook.recalculate_folio_count!

    assert_equal expected_count, notebook.reload.folio_count
  end

  test "discarding cascades to case_documents" do
    notebook = case_notebooks(:principal_notebook)
    document_count = notebook.case_documents.kept.count

    assert document_count > 0

    notebook.discard

    assert notebook.discarded?
    assert_equal 0, notebook.case_documents.kept.count
  end
end
