# frozen_string_literal: true

class CaseNotebook < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  enum :notebook_type, {
    principal: "principal",
    medidas_cautelares: "medidas_cautelares",
    ejecucion: "ejecucion",
    incidentes: "incidentes",
    apelacion: "apelacion",
    casacion: "casacion",
    otro: "otro",
  }

  belongs_to :legal_case

  has_many :case_documents, dependent: :destroy

  validates :notebook_type, presence: true
  validates :code, presence: true
  validates :code, uniqueness: { scope: %i[legal_case_id volume], conditions: -> { kept } }
  validates :volume, numericality: { greater_than: 0 }

  after_discard :discard_associations

  scope :ordered, -> { order(:code, :volume) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id notebook_type code description volume created_at]
  end

  def display_name
    volume > 1 ? "#{code} - #{notebook_type.humanize} (Tomo #{volume})" : "#{code} - #{notebook_type.humanize}"
  end

  def recalculate_folio_count!
    update!(folio_count: case_documents.kept.sum { |d| d.page_count.to_i })
  end

  private

  def discard_associations
    case_documents.discard_all
  end
end
