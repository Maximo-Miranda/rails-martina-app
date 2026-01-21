# frozen_string_literal: true

class LegalCase < ApplicationRecord
  include Discard::Model
  acts_as_tenant :project

  self.discard_column = :deleted_at

  enum :status, {
    activo: "activo",
    archivado: "archivado",
    terminado: "terminado",
    suspendido: "suspendido",
  }, default: :activo

  enum :specialty, {
    civil: "civil",
    penal: "penal",
    laboral: "laboral",
    familia: "familia",
    administrativo: "administrativo",
    constitucional: "constitucional",
    comercial: "comercial",
    tributario: "tributario",
    otro: "otro",
  }

  belongs_to :created_by, class_name: "User"

  has_many :case_notebooks, dependent: :destroy
  has_many :case_documents, through: :case_notebooks
  has_many :court_orders, dependent: :destroy
  has_many :case_reminders, dependent: :destroy

  validates :case_number, presence: true
  validates :case_number, uniqueness: { scope: :project_id, conditions: -> { kept } }
  validates :court, presence: true
  validates :specialty, presence: true
  validates :action_type, presence: true
  validates :filing_date, presence: true
  validates :plaintiff, presence: true
  validates :defendant, presence: true
  validates :lawyer_in_charge, presence: true
  validates :lawyer_phone, presence: true
  validates :lawyer_email, presence: true
  validates :lawyer_professional_card, presence: true

  after_create :create_principal_notebook
  after_discard :discard_associations

  scope :active_cases, -> { where(status: :activo) }
  scope :with_upcoming_terms, -> { where("current_term_date >= ?", Date.current).order(:current_term_date) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id case_number court specialty status action_type plaintiff defendant lawyer_in_charge filing_date created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[created_by case_notebooks]
  end

  def display_name
    "#{case_number} - #{plaintiff} vs #{defendant}"
  end

  private

  def create_principal_notebook
    case_notebooks.create!(notebook_type: :principal, code: "C01", description: "Cuaderno Principal")
  end

  def discard_associations
    case_notebooks.discard_all
    court_orders.discard_all
    case_reminders.discard_all
  end
end
