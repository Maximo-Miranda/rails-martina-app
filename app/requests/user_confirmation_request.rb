# frozen_string_literal: true

class UserConfirmationRequest
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :email

  validates :email, presence: true,
                    format: { with: Devise.email_regexp }
end
