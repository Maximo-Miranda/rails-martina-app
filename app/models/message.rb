# frozen_string_literal: true

class Message < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  enum :role, {
    user_role: 0,
    assistant_role: 1,
  }, prefix: :role

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
  }, default: :pending, prefix: true

  belongs_to :chat, counter_cache: true
  belongs_to :user, optional: true

  has_many :message_citations, dependent: :destroy
  has_many :cited_documents, through: :message_citations, source: :document

  validates :role, presence: true
  validates :content, presence: true
  validate :user_required_for_user_role

  after_create :auto_generate_chat_title, if: :should_generate_title?

  scope :for_context, -> { kept.order(:created_at).limit(Chat::MAX_HISTORY_MESSAGES) }
  scope :user_messages, -> { where(role: :user_role) }
  scope :assistant_messages, -> { where(role: :assistant_role) }
  scope :recent, -> { order(created_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id role status created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[chat user message_citations cited_documents]
  end

  def from_user?
    role_user_role?
  end

  def from_assistant?
    role_assistant_role?
  end

  def gemini_role
    role_user_role? ? "user" : "model"
  end

  private

  def user_required_for_user_role
    return unless role_user_role? && user_id.blank?

    errors.add(:user, :required_for_user_role)
  end

  def should_generate_title?
    role_user_role? && chat.title.blank?
  end

  def auto_generate_chat_title
    chat.generate_title_from_first_message
  end
end
