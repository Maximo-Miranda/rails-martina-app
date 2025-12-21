class UserLoginRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :email, :password

  validates :email, presence: true, format: { with: Devise.email_regexp }
  validates :password, presence: true, length: { minimum: Devise.password_length.min }
end
