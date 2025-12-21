class Users::SessionsController < Devise::SessionsController
  def new
    render inertia: "auth/login", props: {}
  end

  def create
    # Validaciones de campos requeridos
    user_params = params.dig(:user) || {}
    errors = {}
    errors[:email] = [ "El correo electrónico es requerido" ] if user_params[:email].blank?
    errors[:password] = [ "La contraseña es requerida" ] if user_params[:password].blank?

    if errors.any?
      render inertia: "auth/login", props: { errors: errors }
      return
    end

    self.resource = warden.authenticate(auth_options)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      redirect_to dashboard_path
    else
      render inertia: "auth/login", props: {
        errors: { email: [ "Correo electrónico o contraseña inválidos" ] }
      }
    end
  end

  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message!(:notice, :signed_out) if signed_out
    redirect_to new_user_session_path
  end
end
