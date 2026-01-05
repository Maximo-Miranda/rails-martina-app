# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model
  extend FriendlyId
  resourcify

  self.discard_column = :deleted_at

  friendly_id :name, use: :slugged

  belongs_to :user
  has_one :gemini_file_search_store, dependent: :nullify
  has_many :documents, dependent: :destroy
  has_many :chats, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :user_id }

  after_create :assign_owner_role

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name slug description created_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[user]
  end

  private

  def assign_owner_role
    user.add_role(:owner, self)
  end
end
