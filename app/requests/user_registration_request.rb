class UserRegistrationRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :full_name, :email, :password, :password_confirmation

  validates :full_name, presence: { message: "El nombre completo es requerido" }
  validates :email, presence: { message: "El correo electrónico es requerido" },
                    format: { with: Devise.email_regexp, message: "El formato del correo electrónico es inválido" }
  validates :password, presence: { message: "La contraseña es requerida" },
                       length: { minimum: Devise.password_length.min, message: "La contraseña debe tener al menos %{count} caracteres" }
  validates :password_confirmation, presence: { message: "La confirmación de contraseña es requerida" }
  validate :passwords_match

  private

  def passwords_match
    return if password.blank? || password_confirmation.blank?

    if password != password_confirmation
      errors.add(:password_confirmation, "Las contraseñas no coinciden")
    end
  end
end
