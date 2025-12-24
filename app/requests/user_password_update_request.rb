class UserPasswordUpdateRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :password, :password_confirmation, :reset_password_token

  validates :reset_password_token, presence: true
  validates :password, presence: true,
                       length: { minimum: Devise.password_length.min }
  validates :password_confirmation, presence: true
  validate :passwords_match

  private

  def passwords_match
    return if password.blank? || password_confirmation.blank?

    if password != password_confirmation
      errors.add(:password_confirmation, :confirmation)
    end
  end
end
