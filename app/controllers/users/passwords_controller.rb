class Users::PasswordsController < Devise::PasswordsController
  def new
    render inertia: "auth/forgot-password"
  end

  def create
    request = UserPasswordResetRequest.new(resource_params.slice(:email).to_h)

    unless request.valid?
      render inertia: "auth/forgot-password", props: {
        errors: request.errors.messages
      }
      return
    end

    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      redirect_to new_user_session_path, notice: t(".reset_instructions_sent")
    else
      render inertia: "auth/forgot-password", props: {
        errors: resource.errors.messages
      }
    end
  end

  # GET /users/password/edit?reset_password_token=abcdef
  def edit
    render inertia: "auth/reset-password", props: {
      reset_password_token: params[:reset_password_token]
    }
  end

  def update
    request = UserPasswordUpdateRequest.new(resource_params.slice(:password, :password_confirmation, :reset_password_token).to_h)

    unless request.valid?
      render inertia: "auth/reset-password", props: {
        reset_password_token: resource_params[:reset_password_token] || params.dig(:user, :reset_password_token) || "",
        errors: request.errors.messages
      }
      return
    end

    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      redirect_to new_session_path(resource_name), notice: t(".updated_successfully")
    else
      set_minimum_password_length
      render inertia: "auth/reset-password", props: {
        reset_password_token: resource_params[:reset_password_token] || "",
        errors: resource.errors.messages
      }
    end
  end

  private

  def resource_params
    params.permit(:email, :password, :password_confirmation, :reset_password_token)
  end
end
