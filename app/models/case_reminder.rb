# frozen_string_literal: true

class CaseReminder < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  NOTIFICATION_WINDOWS = [
    { type: :notification_3d, threshold: 3.days },
    { type: :notification_1d, threshold: 1.day },
    { type: :notification_4h, threshold: 4.hours },
    { type: :notification_1h, threshold: 1.hour },
  ].freeze

  enum :reminder_type, {
    audiencia: "audiencia",
    vencimiento_termino: "vencimiento_termino",
    presentar_memorial: "presentar_memorial",
    revision_expediente: "revision_expediente",
    pago_arancel: "pago_arancel",
    cita_cliente: "cita_cliente",
    otro: "otro",
  }

  belongs_to :legal_case
  belongs_to :court_order, optional: true
  belongs_to :created_by, class_name: "User"

  has_many :case_reminder_users, dependent: :destroy
  has_many :users, through: :case_reminder_users

  validates :title, presence: true
  validates :reminder_type, presence: true
  validates :reminder_at, presence: true
  validates :custom_type, presence: true, if: -> { otro? }

  after_commit :schedule_notification_jobs, on: :create
  after_commit :reschedule_notification_jobs, on: :update, if: :saved_change_to_reminder_at?
  after_discard :cancel_all_notification_jobs

  scope :upcoming, -> { where("reminder_at > ?", Time.current).order(:reminder_at) }
  scope :past, -> { where("reminder_at <= ?", Time.current).order(reminder_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title reminder_type reminder_at location created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[legal_case court_order users]
  end

  def display_type
    otro? ? custom_type : reminder_type.humanize
  end

  def acknowledged?
    case_reminder_users.exists?(acknowledged: true)
  end

  def acknowledge_for!(user)
    case_reminder_users.find_by(user: user)&.acknowledge!
    cancel_all_notification_jobs if acknowledged?
  end

  def schedule_notification_jobs
    NOTIFICATION_WINDOWS.each do |window|
      schedule_notification_for_window(window)
    end
  end

  def reschedule_notification_jobs
    cancel_all_notification_jobs
    schedule_notification_jobs
  end

  def cancel_all_notification_jobs
    NOTIFICATION_WINDOWS.each do |window|
      cancel_notification_job(window[:type])
    end
  end

  private

  def schedule_notification_for_window(window)
    notification_time = reminder_at - window[:threshold]
    return if notification_time <= Time.current

    job = LegalCases::SendSingleReminderNotificationJob
      .set(wait_until: notification_time)
      .perform_later(id, window[:type].to_s)

    job_id_column = "#{window[:type]}_job_id"
    update_column(job_id_column, job.job_id) # Guardar el UUID de ActiveJob
  end

  def cancel_notification_job(notification_type)
    job_id_column = "#{notification_type}_job_id"
    active_job_id = send(job_id_column)
    return unless active_job_id.present?

    cancel_solid_queue_job(active_job_id)
    update_column(job_id_column, nil)
  end

  def cancel_solid_queue_job(active_job_id)
    return unless defined?(SolidQueue::Job)
    return unless SolidQueue::Job.table_exists?

    SolidQueue::Job.find_by(active_job_id: active_job_id)&.destroy
  rescue ActiveRecord::StatementInvalid
    # Tabla no disponible, ignorar
  end
end
