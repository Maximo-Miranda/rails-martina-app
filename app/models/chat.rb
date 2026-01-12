# frozen_string_literal: true

class Chat < ApplicationRecord
  include Discard::Model
  acts_as_tenant :project

  self.discard_column = :deleted_at

  MAX_CHATS_PER_PROJECT = 100
  MAX_HISTORY_MESSAGES = 25
  MAX_GLOBAL_STORES = 50

  enum :status, {
    active: 0,
    archived: 1,
  }, default: :active

  belongs_to :project
  belongs_to :user
  belongs_to :gemini_file_search_store

  has_and_belongs_to_many :global_stores,
                          class_name: "GeminiFileSearchStore",
                          join_table: "chat_global_stores",
                          foreign_key: "chat_id",
                          association_foreign_key: "gemini_file_search_store_id"

  has_many :messages, dependent: :destroy

  validates :project_id, presence: true
  validates :user_id, presence: true
  validates :gemini_file_search_store_id, presence: true
  validate :max_chats_per_project, on: :create
  validate :store_must_be_synced, on: :create
  validate :store_must_have_documents, on: :create
  validate :global_stores_limit
  validate :global_stores_must_be_global_and_active

  scope :for_user, ->(user) { where(user: user) }
  scope :for_project, ->(project) { where(project: project) }
  scope :recent, -> { order(updated_at: :desc) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id title status created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[project user gemini_file_search_store messages global_stores]
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

  def all_store_names
    names = [ gemini_file_search_store&.gemini_store_name ].compact
    names + global_stores_without_tenant.filter(&:active?).map(&:gemini_store_name).compact
  end

  def all_stores
    stores = [ gemini_file_search_store ].compact
    stores + global_stores_without_tenant.filter(&:active?)
  end

  def global_stores_without_tenant
    @global_stores_without_tenant ||= ActsAsTenant.without_tenant { global_stores.reload.to_a }
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

  def store_must_have_documents
    return unless gemini_file_search_store

    real_count = gemini_file_search_store.documents.kept.active.count
    return if real_count > 0

    errors.add(:gemini_file_search_store, :no_documents)
  end

  def global_stores_limit
    return if global_stores.size <= MAX_GLOBAL_STORES

    errors.add(:global_stores, :too_many, count: MAX_GLOBAL_STORES)
  end

  def global_stores_must_be_global_and_active
    global_stores.each do |store|
      unless store.global?
        errors.add(:global_stores, :must_be_global, name: store.display_name)
        next
      end

      unless store.active?
        errors.add(:global_stores, :must_be_active, name: store.display_name)
      end
    end
  end
end
