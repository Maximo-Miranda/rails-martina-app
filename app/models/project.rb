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

  private

  def assign_owner_role
    user.add_role(:owner, self)
  end
end
