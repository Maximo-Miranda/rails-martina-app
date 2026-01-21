# frozen_string_literal: true

require "test_helper"

class CourtOrderTest < ActiveSupport::TestCase
  setup do
    @project = projects(:test_project)
    @user = users(:confirmed_user)
    @legal_case = legal_cases(:legal_case_one)
    ActsAsTenant.current_tenant = @project
  end

  teardown do
    ActsAsTenant.current_tenant = nil
  end

  test "valid court order" do
    order = CourtOrder.new(
      legal_case: @legal_case,
      created_by: @user,
      order_type: :auto_interlocutorio,
      order_date: Date.current,
      summary: "Test order summary"
    )

    assert order.valid?
    assert_equal "pendiente", order.status
  end

  test "requires order_type" do
    order = CourtOrder.new(
      legal_case: @legal_case,
      created_by: @user,
      order_date: Date.current,
      summary: "Test"
    )

    assert order.invalid?
    assert_includes order.errors.attribute_names, :order_type
  end

  test "requires order_date" do
    order = CourtOrder.new(
      legal_case: @legal_case,
      created_by: @user,
      order_type: :auto_interlocutorio,
      summary: "Test"
    )

    assert order.invalid?
    assert_includes order.errors.attribute_names, :order_date
  end

  test "requires summary" do
    order = CourtOrder.new(
      legal_case: @legal_case,
      created_by: @user,
      order_type: :auto_interlocutorio,
      order_date: Date.current
    )

    assert order.invalid?
    assert_includes order.errors.attribute_names, :summary
  end

  test "default status is pendiente" do
    order = CourtOrder.new

    assert_equal "pendiente", order.status
  end

  test "scope pending returns orders with pendiente status" do
    pending_orders = CourtOrder.pending

    assert pending_orders.all?(&:pendiente?)
  end

  test "scope with_deadline returns orders with deadline ordered by date" do
    orders = CourtOrder.with_deadline

    assert orders.all? { |o| o.deadline.present? }
    deadlines = orders.map(&:deadline)
    assert_equal deadlines.sort, deadlines
  end

  test "scope overdue returns pending orders with past deadline" do
    overdue_orders = CourtOrder.overdue

    assert overdue_orders.all? { |o| o.pendiente? && o.deadline < Date.current }
  end

  test "overdue? returns true when pendiente and deadline passed" do
    order = court_orders(:auto_vencido)

    assert order.overdue?
  end

  test "overdue? returns false when not pendiente" do
    order = court_orders(:auto_admisorio_order)

    assert order.cumplido?
    assert_not order.overdue?
  end

  test "overdue? returns false when no deadline" do
    order = CourtOrder.new(
      legal_case: @legal_case,
      created_by: @user,
      order_type: :auto_interlocutorio,
      order_date: Date.current,
      summary: "Test",
      status: :pendiente,
      deadline: nil
    )

    assert_not order.overdue?
  end

  test "overdue? returns false when deadline in future" do
    order = court_orders(:auto_pruebas)

    assert order.pendiente?
    assert order.deadline > Date.current
    assert_not order.overdue?
  end

  test "days_until_deadline returns positive days for future deadline" do
    order = CourtOrder.new(deadline: 5.days.from_now.to_date)

    assert_equal 5, order.days_until_deadline
  end

  test "days_until_deadline returns negative days for past deadline" do
    order = CourtOrder.new(deadline: 3.days.ago.to_date)

    assert_equal(-3, order.days_until_deadline)
  end

  test "days_until_deadline returns nil when no deadline" do
    order = CourtOrder.new(deadline: nil)

    assert_nil order.days_until_deadline
  end
end
