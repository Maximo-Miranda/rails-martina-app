# frozen_string_literal: true

class CourtOrder < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  enum :order_type, {
    auto_interlocutorio: "auto_interlocutorio",
    auto_de_tramite: "auto_de_tramite",
    sentencia: "sentencia",
    providencia: "providencia",
    resolucion: "resolucion",
    otro: "otro",
  }

  enum :status, {
    pendiente: "pendiente",
    cumplido: "cumplido",
    vencido: "vencido",
    en_apelacion: "en_apelacion",
  }, default: :pendiente

  belongs_to :legal_case
  belongs_to :created_by, class_name: "User"

  has_many :case_reminders, dependent: :nullify

  validates :order_type, presence: true
  validates :order_date, presence: true
  validates :summary, presence: true

  scope :pending, -> { where(status: :pendiente) }
  scope :with_deadline, -> { where.not(deadline: nil).order(:deadline) }
  scope :overdue, -> { pending.where("deadline < ?", Date.current) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id order_type status order_date deadline created_at]
  end

  def overdue?
    pendiente? && deadline.present? && deadline < Date.current
  end

  def days_until_deadline
    return unless deadline.present?

    (deadline - Date.current).to_i
  end
end
