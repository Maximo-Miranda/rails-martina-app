# frozen_string_literal: true

class LegalCasesController < ApplicationController
  include RansackPagyIndex

  before_action :set_legal_case, only: %i[show edit update destroy]

  def index
    authorize LegalCase

    base_scope = policy_scope(LegalCase).kept

    @q, filters = build_ransack(
      base_scope,
      allowed_q_keys: %i[case_number_cont court_cont specialty_eq status_eq plaintiff_cont defendant_cont],
      allowed_sort_fields: %w[case_number court specialty status filing_date current_term_date created_at],
      default_sort: "created_at desc"
    )

    @pagy, legal_cases = pagy(:offset, @q.result(distinct: true), limit: pagy_limit(default: 10))

    render inertia: "LegalCases/Index", props: {
      legalCases: legal_cases.map { |lc| legal_case_json(lc) },
      pagination: pagy_pagination(@pagy),
      filters: filters,
      statuses: LegalCase.statuses.keys,
      specialties: LegalCase.specialties.keys,
    }
  end

  def show
    authorize @legal_case

    render inertia: "LegalCases/Show", props: {
      legalCase: legal_case_detail_json(@legal_case),
      notebooks: @legal_case.case_notebooks.kept.ordered.map { |n| case_notebook_json(n) },
      courtOrders: @legal_case.court_orders.kept.order(order_date: :desc).map { |o| court_order_json(o) },
      reminders: @legal_case.case_reminders.kept.order(:reminder_at).map { |r| case_reminder_json(r) },
    }
  end

  def new
    @legal_case = LegalCase.new
    authorize @legal_case

    render inertia: "LegalCases/Form", props: {
      legalCase: {},
      statuses: LegalCase.statuses.keys,
      specialties: LegalCase.specialties.keys,
    }
  end

  def edit
    authorize @legal_case

    render inertia: "LegalCases/Form", props: {
      legalCase: legal_case_detail_json(@legal_case),
      statuses: LegalCase.statuses.keys,
      specialties: LegalCase.specialties.keys,
    }
  end

  def create
    @legal_case = LegalCase.new(legal_case_params)
    @legal_case.created_by = current_user
    authorize @legal_case

    if @legal_case.save
      redirect_to legal_case_path(@legal_case), notice: t(".success")
    else
      redirect_to new_legal_case_path, inertia: { errors: @legal_case.errors }
    end
  end

  def update
    authorize @legal_case

    if @legal_case.update(legal_case_params)
      redirect_to legal_case_path(@legal_case), notice: t(".success")
    else
      redirect_to edit_legal_case_path(@legal_case), inertia: { errors: @legal_case.errors }
    end
  end

  def destroy
    authorize @legal_case

    @legal_case.discard
    redirect_to legal_cases_path, notice: t(".success")
  end

  private

  def set_legal_case
    @legal_case = LegalCase.kept.find(params[:id])
  end

  def legal_case_params
    params.require(:legal_case).permit(
      :case_number, :court, :specialty, :status, :action_type, :filing_date,
      :plaintiff, :defendant, :plaintiff_lawyer, :defendant_lawyer,
      :lawyer_in_charge, :lawyer_phone, :lawyer_email, :lawyer_professional_card,
      :current_term_date, :last_action_date, :notes
    )
  end

  def legal_case_json(legal_case)
    {
      id: legal_case.id,
      caseNumber: legal_case.case_number,
      court: legal_case.court,
      specialty: legal_case.specialty,
      status: legal_case.status,
      actionType: legal_case.action_type,
      plaintiff: legal_case.plaintiff,
      defendant: legal_case.defendant,
      filingDate: legal_case.filing_date,
      currentTermDate: legal_case.current_term_date,
      createdAt: legal_case.created_at,
    }
  end

  def legal_case_detail_json(legal_case)
    legal_case_json(legal_case).merge(
      plaintiffLawyer: legal_case.plaintiff_lawyer,
      defendantLawyer: legal_case.defendant_lawyer,
      lawyerInCharge: legal_case.lawyer_in_charge,
      lawyerPhone: legal_case.lawyer_phone,
      lawyerEmail: legal_case.lawyer_email,
      lawyerProfessionalCard: legal_case.lawyer_professional_card,
      lastActionDate: legal_case.last_action_date,
      notes: legal_case.notes,
      createdById: legal_case.created_by_id
    )
  end

  def case_notebook_json(notebook)
    {
      id: notebook.id,
      notebookType: notebook.notebook_type,
      code: notebook.code,
      description: notebook.description,
      volume: notebook.volume,
      folioCount: notebook.folio_count,
      documentsCount: notebook.case_documents.kept.count,
    }
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
    }
  end

  def case_reminder_json(reminder)
    {
      id: reminder.id,
      title: reminder.title,
      reminderType: reminder.reminder_type,
      displayType: reminder.display_type,
      description: reminder.description,
      reminderAt: reminder.reminder_at,
      location: reminder.location,
      acknowledged: reminder.acknowledged?,
    }
  end
end
