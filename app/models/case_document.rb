# frozen_string_literal: true

class CaseDocument < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  MAX_FILE_SIZE = 100.megabytes.freeze

  enum :document_type, {
    demanda: 0,
    contestacion: 1,
    auto: 2,
    sentencia: 3,
    recurso: 4,
    memorial: 5,
    prueba: 6,
    notificacion: 7,
    poder: 8,
    dictamen: 9,
    acta: 10,
    otro: 99,
  }

  belongs_to :case_notebook
  belongs_to :uploaded_by, class_name: "User"
  belongs_to :document, optional: true

  has_one :legal_case, through: :case_notebook
  has_one_attached :file

  validates :document_type, presence: true
  validates :name, presence: true
  validates :description, presence: true
  validates :folio_start, presence: true, numericality: { greater_than: 0 }
  validates :folio_end, presence: true, numericality: { greater_than_or_equal_to: ->(record) { record.folio_start || 0 } }
  validates :page_count, presence: true, numericality: { greater_than: 0 }
  validates :document_date, presence: true
  validates :issuer, presence: true
  validates :file, presence: true, on: :create
  validates :item_number, uniqueness: { scope: :case_notebook_id, conditions: -> { kept } }, allow_nil: true
  validate :file_size_within_limit, if: -> { file.attached? }

  before_create :assign_next_item_number
  after_save :update_notebook_folio_count
  after_discard :update_notebook_folio_count
  after_discard :discard_ai_document

  scope :ordered, -> { order(:item_number) }
  scope :with_ai, -> { where.not(document_id: nil) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id document_type name item_number document_date issuer created_at]
  end

  def ai_enabled?
    document.present?
  end

  def foliation
    return unless folio_start && folio_end

    folio_start == folio_end ? folio_start.to_s : "#{folio_start}-#{folio_end}"
  end

  private

  def assign_next_item_number
    return if item_number.present?

    max_item = case_notebook.case_documents.kept.maximum(:item_number) || 0
    self.item_number = max_item + 1
  end

  def file_size_within_limit
    return unless file.blob.byte_size > MAX_FILE_SIZE

    errors.add(:file, :too_large, max_size: ActiveSupport::NumberHelper.number_to_human_size(MAX_FILE_SIZE))
  end

  def update_notebook_folio_count
    case_notebook.recalculate_folio_count!
  end

  def discard_ai_document
    document&.discard
  end
end
