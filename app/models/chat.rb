# frozen_string_literal: true

class Chat < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  MAX_CHATS_PER_PROJECT = 100
  MAX_HISTORY_MESSAGES = 25

  enum :status, {
    active: 0,
    archived: 1,
  }, default: :active

  belongs_to :project
  belongs_to :user
  belongs_to :gemini_file_search_store

  has_many :messages, dependent: :destroy

  validates :project_id, presence: true
  validates :user_id, presence: true
  validates :gemini_file_search_store_id, presence: true
  validate :max_chats_per_project, on: :create
  validate :store_must_be_synced, on: :create

  scope :for_user, ->(user) { where(user: user) }
  scope :for_project, ->(project) { where(project: project) }
  scope :recent, -> { order(updated_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title status created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project user gemini_file_search_store messages]
  end

  def owned_by?(check_user)
    user_id == check_user.id
  end

  def history_for_context
    messages.kept.order(:created_at).limit(MAX_HISTORY_MESSAGES).map do |msg|
      { role: msg.gemini_role, content: msg.content }
    end
  end

  # Auto-generates title from first user message
  def generate_title_from_first_message
    return if title.present?

    first_message = messages.kept.user_messages.order(:created_at).first
    return unless first_message

    update(title: build_title_from(first_message.content))
  end

  def display_title
    title.presence || I18n.t("chats.default_title")
  end

  private

  MAX_TITLE_LENGTH = 50

  def build_title_from(text)
    cleaned = text.squish
    return cleaned if cleaned.length <= MAX_TITLE_LENGTH

    truncate_at_word_boundary(cleaned)
  end

  def truncate_at_word_boundary(text)
    text.truncate(MAX_TITLE_LENGTH, separator: " ", omission: "…")
  end

  def max_chats_per_project
    return unless project_id

    count = Chat.kept.where(project_id: project_id).count
    return unless count >= MAX_CHATS_PER_PROJECT
      errors.add(:base, :max_chats_reached, count: MAX_CHATS_PER_PROJECT)
  end

  def store_must_be_synced
    return unless gemini_file_search_store

    return if gemini_file_search_store.synced?
      errors.add(:gemini_file_search_store, :not_synced)
  end
end
