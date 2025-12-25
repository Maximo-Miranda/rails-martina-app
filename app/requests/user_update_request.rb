class UserUpdateRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :full_name, :email

  validates :full_name, presence: true
  validates :email, presence: true,
                    format: { with: Devise.email_regexp }
end
