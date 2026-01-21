# frozen_string_literal: true

class CourtOrdersController < ApplicationController
  before_action :set_legal_case
  before_action :set_court_order, only: %i[show update destroy]

  def index
    authorize CourtOrder

    # TODO: Add pagination, sorting, filtering.
    orders = @legal_case.court_orders.kept.order(order_date: :desc)

    render inertia: "CourtOrders/Index", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      courtOrders: orders.map { |o| court_order_json(o) },
      orderTypes: CourtOrder.order_types.keys,
      statuses: CourtOrder.statuses.keys,
    }
  end

  def new
    @court_order = @legal_case.court_orders.build
    authorize @court_order

    render inertia: "CourtOrders/Form", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      courtOrder: {},
      orderTypes: CourtOrder.order_types.keys,
      statuses: CourtOrder.statuses.keys,
    }
  end

  def show
    authorize @court_order

    render inertia: "CourtOrders/Show", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      courtOrder: court_order_detail_json(@court_order),
      reminders: @court_order.case_reminders.kept.map { |r| case_reminder_json(r) },
    }
  end

  def create
    @court_order = @legal_case.court_orders.build(court_order_params)
    @court_order.created_by = current_user
    authorize @court_order

    if @court_order.save
      redirect_to legal_case_path(@legal_case, tab: "orders"), notice: t(".success")
    else
      redirect_to legal_case_path(@legal_case, tab: "orders"), inertia: { errors: @court_order.errors }
    end
  end

  def update
    authorize @court_order

    if @court_order.update(court_order_params)
      redirect_to legal_case_court_order_path(@legal_case, @court_order), notice: t(".success")
    else
      redirect_to legal_case_court_order_path(@legal_case, @court_order), inertia: { errors: @court_order.errors }
    end
  end

  def destroy
    authorize @court_order

    @court_order.discard
    redirect_to legal_case_path(@legal_case, tab: "orders"), notice: t(".success")
  end

  private

  def set_legal_case
    @legal_case = LegalCase.kept.find(params[:legal_case_id])
  end

  def set_court_order
    @court_order = @legal_case.court_orders.kept.find(params[:id])
  end

  def court_order_params
    params.require(:court_order).permit(:order_type, :summary, :order_date, :deadline, :status)
  end

  def court_order_json(order)
    {
      id: order.id,
      orderType: order.order_type,
      summary: order.summary,
      orderDate: order.order_date,
      deadline: order.deadline,
      status: order.status,
      overdue: order.overdue?,
      daysUntilDeadline: order.days_until_deadline,
      createdAt: order.created_at,
    }
  end

  def court_order_detail_json(order)
    court_order_json(order).merge(
      createdById: order.created_by_id
    )
  end

  def case_reminder_json(reminder)
    {
      id: reminder.id,
      title: reminder.title,
      reminderType: reminder.reminder_type,
      reminderAt: reminder.reminder_at,
    }
  end
end
