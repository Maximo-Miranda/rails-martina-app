# frozen_string_literal: true

class GeminiFileSearchStore < ApplicationRecord
  include Discard::Model
  acts_as_tenant :project, optional: true

  self.discard_column = :deleted_at

  enum :status, {
    pending: 0,
    active: 1,
    failed: 2,
    deleted: 3,
  }, default: :pending

  validates :display_name, presence: true
  validates :gemini_store_name, uniqueness: true, allow_nil: true

  # Soft constraint: Enforce 1-to-1 at app level to allow future db evolution to 1-to-many
  validates :project_id, uniqueness: true, allow_nil: true

  scope :global, -> { where(project_id: nil) }
  scope :for_project, ->(project) { where(project: project) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id display_name gemini_store_name status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project]
  end

  def global?
    project_id.nil?
  end

  def synced?
    gemini_store_name.present? && active?
  end
end
