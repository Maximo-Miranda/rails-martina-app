class Users::SessionsController < Devise::SessionsController
  def new
    render inertia: "auth/login", props: {}
  end

  def create
    self.resource = warden.authenticate(auth_options)

    if resource
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      redirect_to after_sign_in_path_for(resource)
    else
      render inertia: "auth/login", props: {
        errors: { email: [ "Correo electrónico o contraseña inválidos" ] }
      }
    end
  end
end
