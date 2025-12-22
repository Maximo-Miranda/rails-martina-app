class UserProfileUpdateRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :full_name, :email, :current_password, :password, :password_confirmation

  validates :full_name, presence: true
  validates :email, presence: true,
                    format: { with: Devise.email_regexp }

  validate :password_fields_if_changing_password

  def changing_password?
    password.present? || password_confirmation.present?
  end

  private

  def password_fields_if_changing_password
    return unless changing_password?

    if current_password.blank?
      errors.add(:current_password, :blank)
    end

    if password.blank?
      errors.add(:password, :blank)
    elsif password.length < Devise.password_length.min
      errors.add(:password, :too_short, count: Devise.password_length.min)
    end

    if password_confirmation.blank?
      errors.add(:password_confirmation, :blank)
    elsif password.present? && password != password_confirmation
      errors.add(:password_confirmation, :confirmation)
    end
  end
end
