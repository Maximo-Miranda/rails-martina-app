# frozen_string_literal: true

require "test_helper"

class LegalCaseTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "valid legal case" do
    legal_case = LegalCase.new(
      project: @project,
      created_by: @user,
      case_number: "2024-99999-00",
      court: "Juzgado Test",
      specialty: :civil,
      action_type: "Proceso Test",
      filing_date: Date.current,
      plaintiff: "Demandante Test",
      defendant: "Demandado Test",
      lawyer_in_charge: "Abogado Test",
      lawyer_phone: "123456789",
      lawyer_email: "abogado@test.com",
      lawyer_professional_card: "TP-12345"
    )

    assert legal_case.valid?
    assert_equal "activo", legal_case.status
  end

  test "requires essential fields" do
    legal_case = LegalCase.new

    assert legal_case.invalid?
    assert_includes legal_case.errors.attribute_names, :case_number
    assert_includes legal_case.errors.attribute_names, :court
    assert_includes legal_case.errors.attribute_names, :specialty
    assert_includes legal_case.errors.attribute_names, :action_type
    assert_includes legal_case.errors.attribute_names, :filing_date
    assert_includes legal_case.errors.attribute_names, :plaintiff
    assert_includes legal_case.errors.attribute_names, :defendant
    assert_includes legal_case.errors.attribute_names, :lawyer_in_charge
    assert_includes legal_case.errors.attribute_names, :lawyer_phone
    assert_includes legal_case.errors.attribute_names, :lawyer_email
    assert_includes legal_case.errors.attribute_names, :lawyer_professional_card
  end

  test "case_number must be unique within project" do
    existing = legal_cases(:legal_case_one)

    duplicate = LegalCase.new(
      project: @project,
      created_by: @user,
      case_number: existing.case_number,
      court: "Otro Juzgado",
      specialty: :civil,
      action_type: "Otro Proceso",
      filing_date: Date.current,
      plaintiff: "Otro Demandante",
      defendant: "Otro Demandado",
      lawyer_in_charge: "Otro Abogado",
      lawyer_phone: "987654321",
      lawyer_email: "otro@test.com",
      lawyer_professional_card: "TP-99999"
    )

    assert duplicate.invalid?
    assert_includes duplicate.errors.attribute_names, :case_number
  end

  test "creates principal notebook after create" do
    legal_case = LegalCase.create!(
      project: @project,
      created_by: @user,
      case_number: "2024-88888-00",
      court: "Juzgado Test",
      specialty: :civil,
      action_type: "Proceso Test",
      filing_date: Date.current,
      plaintiff: "Demandante Test",
      defendant: "Demandado Test",
      lawyer_in_charge: "Abogado Test",
      lawyer_phone: "123456789",
      lawyer_email: "abogado@test.com",
      lawyer_professional_card: "TP-12345"
    )

    assert_equal 1, legal_case.case_notebooks.count
    notebook = legal_case.case_notebooks.first
    assert_equal "principal", notebook.notebook_type
    assert_equal "C01", notebook.code
  end

  test "discarding cascades to associations" do
    legal_case = legal_cases(:legal_case_one)
    notebook_count = legal_case.case_notebooks.count
    order_count = legal_case.court_orders.count
    reminder_count = legal_case.case_reminders.count

    assert notebook_count > 0

    legal_case.discard

    assert legal_case.discarded?
    assert legal_case.case_notebooks.kept.count.zero?
    assert legal_case.court_orders.kept.count.zero?
    assert legal_case.case_reminders.kept.count.zero?
  end

  test "display_name returns formatted string" do
    legal_case = legal_cases(:legal_case_one)

    assert_equal "#{legal_case.case_number} - #{legal_case.plaintiff} vs #{legal_case.defendant}", legal_case.display_name
  end

  test "scope active_cases returns only active cases" do
    active_cases = LegalCase.active_cases

    assert active_cases.all? { |c| c.activo? }
    assert_not active_cases.include?(legal_cases(:archived_case))
  end

  test "scope with_upcoming_terms returns cases with future term dates" do
    upcoming = LegalCase.with_upcoming_terms

    assert upcoming.all? { |c| c.current_term_date && c.current_term_date >= Date.current }
  end
end
