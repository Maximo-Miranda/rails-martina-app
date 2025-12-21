class Users::PasswordsController < Devise::PasswordsController
  # GET /users/password/new
  def new
    render inertia: "auth/forgot-password", props: {}
  end

  # POST /users/password
  def create
    # Validar que el email esté presente
    if resource_params[:email].blank?
      render inertia: "auth/forgot-password", props: {
        errors: { email: [ "El correo electrónico es requerido" ] }
      }
      return
    end

    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      redirect_to new_user_session_path, notice: "Recibirás un correo con instrucciones para restablecer tu contraseña."
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

  # PUT /users/password
  def update
    # Validaciones manuales para campos requeridos
    errors = {}
    errors[:password] = [ "La contraseña es requerida" ] if resource_params[:password].blank?
    errors[:password_confirmation] = [ "La confirmación de contraseña es requerida" ] if resource_params[:password_confirmation].blank?
    errors[:reset_password_token] = [ "El token de restablecimiento es inválido" ] if resource_params[:reset_password_token].blank?

    if errors.any?
      render inertia: "auth/reset-password", props: {
        reset_password_token: resource_params[:reset_password_token] || params.dig(:user, :reset_password_token) || "",
        errors: errors
      }
      return
    end

    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access! if unlockable?(resource)
      if Devise.sign_in_after_reset_password
        set_flash_message!(:notice, :updated_not_active)
        sign_in(resource_name, resource)
        redirect_to after_sign_in_path_for(resource)
      else
        set_flash_message!(:notice, :updated)
        redirect_to new_session_path(resource_name)
      end
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
