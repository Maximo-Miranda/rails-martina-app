class UserProfileUpdateRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :full_name, :email, :current_password, :password, :password_confirmation

  validates :full_name, presence: { message: "El nombre completo es requerido" }
  validates :email, presence: { message: "El correo electrónico es requerido" },
                    format: { with: Devise.email_regexp, message: "El formato del correo electrónico es inválido" }

  validate :password_fields_if_changing_password

  def changing_password?
    password.present? || password_confirmation.present?
  end

  private

  def password_fields_if_changing_password
    return unless changing_password?

    if current_password.blank?
      errors.add(:current_password, "La contraseña actual es requerida")
    end

    if password.blank?
      errors.add(:password, "La nueva contraseña es requerida")
    elsif password.length < Devise.password_length.min
      errors.add(:password, "La contraseña debe tener al menos #{Devise.password_length.min} caracteres")
    end

    if password_confirmation.blank?
      errors.add(:password_confirmation, "La confirmación es requerida")
    elsif password.present? && password != password_confirmation
      errors.add(:password_confirmation, "Las contraseñas no coinciden")
    end
  end
end
