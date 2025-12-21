class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_account_update_params, only: [ :update ]

  def new
    render inertia: "auth/register", props: {}
  end

  def create
    # Validaciones de campos requeridos
    errors = {}
    errors[:full_name] = [ "El nombre completo es requerido" ] if sign_up_params[:full_name].blank?
    errors[:email] = [ "El correo electrónico es requerido" ] if sign_up_params[:email].blank?
    errors[:password] = [ "La contraseña es requerida" ] if sign_up_params[:password].blank?
    errors[:password_confirmation] = [ "La confirmación de contraseña es requerida" ] if sign_up_params[:password_confirmation].blank?

    if errors.any?
      render inertia: "auth/register", props: { errors: errors }
      return
    end

    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        redirect_to new_session_path(resource_name)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length

      render inertia: "auth/register", props: {
        errors: resource.errors.messages
      }
    end
  end

  def edit
    render inertia: "auth/profile", props: {
      user: user_props
    }
  end

  def update
    # Validaciones de campos requeridos
    errors = {}
    errors[:full_name] = [ "El nombre completo es requerido" ] if account_update_params[:full_name].blank?
    errors[:email] = [ "El correo electrónico es requerido" ] if account_update_params[:email].blank?

    # Si se intenta cambiar contraseña, validar campos
    if account_update_params[:password].present? || account_update_params[:password_confirmation].present?
      errors[:current_password] = [ "La contraseña actual es requerida" ] if account_update_params[:current_password].blank?
      errors[:password] = [ "La nueva contraseña es requerida" ] if account_update_params[:password].blank?
      errors[:password_confirmation] = [ "La confirmación es requerida" ] if account_update_params[:password_confirmation].blank?
    end

    if errors.any?
      render inertia: "auth/profile", props: {
        user: user_props,
        errors: errors
      }
      return
    end

    # Determinar si se está actualizando la contraseña
    successfully_updated = if needs_password_update?
      resource.update_with_password(account_update_params)
    else
      resource.update_without_password(account_update_params.except(:current_password, :password, :password_confirmation))
    end

    if successfully_updated
      bypass_sign_in(resource) if account_update_params[:password].present?
      redirect_to edit_user_registration_path, notice: "Perfil actualizado correctamente"
    else
      render inertia: "auth/profile", props: {
        user: user_props,
        errors: resource.errors.messages
      }
    end
  end

  private

  def sign_up_params
    params.permit(:full_name, :email, :password, :password_confirmation)
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :full_name ])
  end

  def account_update_params
    params.require(:user).permit(:full_name, :email, :current_password, :password, :password_confirmation)
  end

  def user_props
    {
      id: resource.id,
      full_name: resource.full_name,
      email: resource.email,
      created_at: resource.created_at.strftime("%d/%m/%Y"),
      last_sign_in_at: resource.last_sign_in_at&.strftime("%d/%m/%Y %H:%M"),
      sign_in_count: resource.sign_in_count
    }
  end

  def needs_password_update?
    account_update_params[:password].present?
  end
end
