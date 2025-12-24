class User < ApplicationRecord
  include Discard::Model
  self.discard_column = :deleted_at
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable

  validates :full_name, presence: true
end
