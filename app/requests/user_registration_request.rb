# frozen_string_literal: true

class UserRegistrationRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :full_name, :email, :password, :password_confirmation

  validates :full_name, presence: true
  validates :email, presence: true,
                    format: { with: Devise.email_regexp }
  validates :password, presence: true,
                       length: { minimum: Devise.password_length.min }
  validates :password_confirmation, presence: true
  validate :passwords_match

  private

  def passwords_match
    return if password.blank? || password_confirmation.blank?

    return unless password != password_confirmation
      errors.add(:password_confirmation, :confirmation)
  end
end
