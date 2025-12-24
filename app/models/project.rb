class Project < ApplicationRecord
  include Discard::Model
  extend FriendlyId
  resourcify

  self.discard_column = :deleted_at

  friendly_id :name, use: :slugged

  belongs_to :user

  validates :name, presence: true

  # Asignar rol owner al creador
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
