# frozen_string_literal: true

class MessageCitation < ApplicationRecord
  belongs_to :message
  belongs_to :document

  validates :message_id, uniqueness: { scope: :document_id }
  validates :confidence_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, allow_nil: true

  scope :high_confidence, -> { where("confidence_score >= ?", 0.7) }
  scope :with_pages, -> { where.not(pages: []) }

  def self.ransackable_attributes(_auth_object = nil)
    %w[id pages confidence_score created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[message document]
  end

  def to_api_hash
    doc = document_without_tenant
    {
      id: id,
      document_id: document_id,
      document_name: doc&.display_name,
      pages: pages,
      text_snippet: text_snippet,
      confidence_score: confidence_score,
      is_global: doc&.global?,
    }
  end

  def document_without_tenant
    @document_without_tenant ||= ActsAsTenant.without_tenant { Document.find_by(id: document_id) }
  end

  def document_file_url
    return nil unless document.file.attached?

    base_url = Rails.application.routes.url_helpers.rails_blob_url(
      document.file,
      host: default_url_host
    )

    pages.present? ? "#{base_url}#page=#{pages.first}" : base_url
  end

  def pages_formatted
    return nil if pages.blank?

    if pages.size == 1
      I18n.t("chats.citations.single_page", page: pages.first)
    else
      I18n.t("chats.citations.multiple_pages", pages: pages.join(", "))
    end
  end

  private

  def default_url_host
    Rails.application.config.action_mailer.default_url_options&.dig(:host) || "localhost:3000"
  end
end
