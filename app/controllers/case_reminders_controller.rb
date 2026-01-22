# frozen_string_literal: true

class CaseRemindersController < ApplicationController
  before_action :set_legal_case
  before_action :set_case_reminder, only: %i[show edit update destroy acknowledge]

  def index
    authorize CaseReminder

    # TODO: Add pagination, sorting, filtering.
    reminders = @legal_case.case_reminders.kept.order(:reminder_at)

    render inertia: "CaseReminders/Index", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      reminders: reminders.map { |r| case_reminder_json(r) },
      reminderTypes: CaseReminder.reminder_types.keys,
      projectUsers: project_users_json,
      currentUserId: current_user.id,
    }
  end

  def new
    @case_reminder = @legal_case.case_reminders.build
    authorize @case_reminder

    render inertia: "CaseReminders/Form", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      reminder: {},
      reminderTypes: CaseReminder.reminder_types.keys,
      projectUsers: project_users_json,
    }
  end

  def edit
    authorize @case_reminder

    render inertia: "CaseReminders/Form", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      reminder: case_reminder_form_json(@case_reminder),
      reminderTypes: CaseReminder.reminder_types.keys,
      projectUsers: project_users_json,
    }
  end

  def show
    authorize @case_reminder

    render inertia: "CaseReminders/Show", props: {
      legalCase: { id: @legal_case.id, caseNumber: @legal_case.case_number },
      reminder: case_reminder_detail_json(@case_reminder),
      users: @case_reminder.case_reminder_users.includes(:user).map { |ru| reminder_user_json(ru) },
    }
  end

  def create
    @case_reminder = @legal_case.case_reminders.build(case_reminder_params)
    @case_reminder.created_by = current_user
    authorize @case_reminder

    if @case_reminder.save
      assign_users_to_reminder
      redirect_to legal_case_path(@legal_case, tab: "reminders"), notice: t(".success")
    else
      redirect_to legal_case_path(@legal_case, tab: "reminders"), inertia: { errors: @case_reminder.errors }
    end
  end

  def update
    authorize @case_reminder

    if @case_reminder.update(case_reminder_params)
      redirect_to legal_case_case_reminder_path(@legal_case, @case_reminder), notice: t(".success")
    else
      redirect_to legal_case_case_reminder_path(@legal_case, @case_reminder),
                  inertia: { errors: @case_reminder.errors }
    end
  end

  def destroy
    authorize @case_reminder

    @case_reminder.discard
    redirect_to legal_case_path(@legal_case, tab: "reminders"), notice: t(".success")
  end

  def acknowledge
    authorize @case_reminder

    @case_reminder.acknowledge_for!(current_user)
    redirect_to legal_case_case_reminder_path(@legal_case, @case_reminder), notice: t(".success")
  end

  private

  def set_legal_case
    @legal_case = LegalCase.kept.find(params[:legal_case_id])
  end

  def set_case_reminder
    @case_reminder = @legal_case.case_reminders.kept.find(params[:id])
  end

  def case_reminder_params
    params.require(:case_reminder).permit(
      :title, :reminder_type, :custom_type, :description, :reminder_at, :location, :court_order_id
    )
  end

  def assign_users_to_reminder
    user_ids = Array(params[:user_ids]).map(&:to_i)
    user_ids << current_user.id
    user_ids.uniq.each do |user_id|
      @case_reminder.case_reminder_users.find_or_create_by(user_id: user_id)
    end
  end

  def case_reminder_json(reminder)
    {
      id: reminder.id,
      title: reminder.title,
      reminderType: reminder.reminder_type,
      displayType: reminder.display_type,
      reminderAt: reminder.reminder_at,
      location: reminder.location,
      acknowledged: reminder.acknowledged?,
      createdAt: reminder.created_at,
    }
  end

  def case_reminder_detail_json(reminder)
    case_reminder_json(reminder).merge(
      description: reminder.description,
      customType: reminder.custom_type,
      courtOrderId: reminder.court_order_id,
      createdById: reminder.created_by_id
    )
  end

  def case_reminder_form_json(reminder)
    {
      id: reminder.id,
      title: reminder.title,
      reminderType: reminder.reminder_type,
      customType: reminder.custom_type,
      description: reminder.description,
      reminderAt: reminder.reminder_at&.strftime("%Y-%m-%dT%H:%M"),
      location: reminder.location,
      userIds: reminder.case_reminder_users.pluck(:user_id),
    }
  end

  def reminder_user_json(reminder_user)
    {
      id: reminder_user.id,
      userId: reminder_user.user_id,
      userName: reminder_user.user.full_name || reminder_user.user.email,
      acknowledged: reminder_user.acknowledged,
      acknowledgedAt: reminder_user.acknowledged_at,
    }
  end

  def project_users_json
    current_project.members.map { |u| { id: u.id, name: u.full_name || u.email } }
  end
end
