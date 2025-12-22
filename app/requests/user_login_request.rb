class UserLoginRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :email, :password

  validates :email, presence: { message: "El correo electrónico es requerido" },
                    format: { with: Devise.email_regexp, message: "El formato del correo electrónico es inválido" }
  validates :password, presence: { message: "La contraseña es requerida" },
                       length: { minimum: Devise.password_length.min, message: "La contraseña debe tener al menos %{count} caracteres" }
end
