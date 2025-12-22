class UserConfirmationRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :email

  validates :email, presence: { message: "El correo electrónico es requerido" },
                    format: { with: Devise.email_regexp, message: "El formato del correo electrónico es inválido" }
end
