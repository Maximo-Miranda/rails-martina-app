# frozen_string_literal: true

class Users::ConfirmationsController < Devise::ConfirmationsController
  rate_limit to: 5, within: 3.minutes, only: :create
  def new
    render inertia: "auth/resend-confirmation"
  end

  def create
    request = UserConfirmationRequest.new(resource_params.to_h)

    unless request.valid?
      flash.now[:alert] = t(".error")
      render inertia: "auth/resend-confirmation", props: {
        errors: request.errors.messages,
      }
      return
    end

    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      redirect_to new_user_session_path, notice: t(".instructions_sent")
    else
      flash.now[:alert] = t(".error")
      render inertia: "auth/resend-confirmation", props: {
        errors: resource.errors.messages,
      }
    end
  end

  # GET /users/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      redirect_to new_user_session_path, notice: t(".confirmed")
    else
      flash.now[:alert] = t(".error")
      render inertia: "auth/confirmation", props: {
        confirmation_token: params[:confirmation_token],
        errors: resource.errors.messages,
      }
    end
  end

  private

  def resource_params
    params.permit(:email)
  end
end
