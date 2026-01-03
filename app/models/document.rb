# frozen_string_literal: true

class Document < ApplicationRecord
  include Discard::Model
  acts_as_tenant :project, optional: true

  self.discard_column = :deleted_at

  # === Constantes ===
  MAX_FILE_SIZE = 100.megabytes.freeze
  MAX_STORE_SIZE = 20.gigabytes.freeze

  SUPPORTED_CONTENT_TYPES = {
    "application/pdf" => ".pdf",
    "application/msword" => ".doc",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => ".docx",
    "application/vnd.ms-excel" => ".xls",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => ".xlsx",
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" => ".pptx",
    "application/vnd.oasis.opendocument.text" => ".odt",
    "text/plain" => ".txt",
    "text/markdown" => ".md",
    "text/csv" => ".csv",
  }.freeze

  METADATA_KEYS = %w[category tags author document_date language version notes].freeze

  # === Enums ===
  enum :status, {
    pending: 0,
    processing: 1,
    active: 2,
    failed: 3,
    deleted: 4,
  }, default: :pending

  # === Associations ===
  belongs_to :gemini_file_search_store
  belongs_to :uploaded_by, class_name: "User"
  has_one_attached :file

  # === Validations ===
  validates :display_name, presence: true
  validates :content_type, presence: true, inclusion: { in: SUPPORTED_CONTENT_TYPES.keys }
  validates :size_bytes, presence: true, numericality: { less_than_or_equal_to: MAX_FILE_SIZE }
  validates :file_hash, presence: true
  validates :file_hash, uniqueness: { scope: :gemini_file_search_store_id, message: :duplicate_in_store, conditions: -> { kept } }
  validates :remote_id, uniqueness: true, allow_nil: true
  validate :store_has_capacity, on: :create
  validate :file_attached, on: :create

  # === Callbacks ===
  before_validation :compute_file_hash, on: :create, if: -> { file.attached? && file_hash.blank? }
  before_validation :set_file_metadata, on: :create, if: -> { file.attached? }

  # === Scopes ===
  scope :global, -> { where(project_id: nil) }
  scope :for_project, ->(project) { where(project: project) }
  scope :for_store, ->(store) { where(gemini_file_search_store: store) }
  scope :synced, -> { where.not(remote_id: nil).active }

  # === Class Methods ===
  def self.ransackable_attributes(_auth_object = nil)
    %w[id display_name content_type status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project gemini_file_search_store uploaded_by]
  end

  def self.extension_for_content_type(content_type)
    SUPPORTED_CONTENT_TYPES[content_type]
  end

  # === Instance Methods ===
  def global?
    project_id.nil?
  end

  def synced?
    remote_id.present? && active?
  end

  def store_available_bytes
    MAX_STORE_SIZE - gemini_file_search_store.size_bytes
  end

  def duplicate_exists?
    return false if file_hash.blank?

    Document.kept
            .where(gemini_file_search_store_id: gemini_file_search_store_id)
            .where(file_hash: file_hash)
            .where.not(id: id)
            .exists?
  end

  private

  def compute_file_hash
    return unless file.attached?

    self.file_hash = if file.blob.persisted?
                       # Blob already saved to storage
                       file.blob.open { |f| Digest::SHA256.file(f.path).hexdigest }
    elsif file.blob.byte_size.present?
                       # Blob exists but not persisted - use checksum as proxy
                       # Active Storage computes MD5 checksum, we'll use it + size for uniqueness
                       Digest::SHA256.hexdigest("#{file.blob.checksum}:#{file.blob.byte_size}")
    end
  end

  def set_file_metadata
    return unless file.attached?

    self.content_type = file.content_type
    self.size_bytes = file.byte_size
    self.display_name = file.filename.to_s if display_name.blank?
  end

  def store_has_capacity
    return if gemini_file_search_store.blank?

    current_size = gemini_file_search_store.size_bytes || 0
    return unless current_size + size_bytes.to_i > MAX_STORE_SIZE
      errors.add(:base, :store_capacity_exceeded,
        available: ActiveSupport::NumberHelper.number_to_human_size(MAX_STORE_SIZE - current_size),
        required: ActiveSupport::NumberHelper.number_to_human_size(size_bytes))
  end

  def file_attached
    errors.add(:file, :blank) unless file.attached?
  end
end
