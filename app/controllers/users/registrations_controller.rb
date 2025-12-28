# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  rate_limit to: 5, within: 1.minute, only: :create
  before_action :configure_account_update_params, only: [ :update ]

  def new
    render inertia: "auth/register"
  end

  def create
    request = UserRegistrationRequest.new(sign_up_params.to_h)

    unless request.valid?
      flash.now[:alert] = t(".error")
      render inertia: "auth/register", props: { errors: request.errors.messages }
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

      flash.now[:alert] = t(".error")
      render inertia: "auth/register", props: {
        errors: resource.errors.messages,
      }
    end
  end

  def edit
    render inertia: "auth/profile", props: {
      user: user_props,
    }
  end

  def update
    request = UserProfileUpdateRequest.new(account_update_params.to_h)

    unless request.valid?
      flash.now[:alert] = t(".error")
      render inertia: "auth/profile", props: {
        user: user_props,
        errors: request.errors.messages,
      }
      return
    end

    # Determinar si se está actualizando la contraseña
    successfully_updated = if request.changing_password?
      resource.update_with_password(account_update_params)
    else
      resource.update_without_password(account_update_params.except(:current_password, :password, :password_confirmation))
    end

    if successfully_updated
      bypass_sign_in(resource) if account_update_params[:password].present?
      redirect_to edit_user_registration_path, notice: t(".profile_updated")
    else
      flash.now[:alert] = t(".error")
      render inertia: "auth/profile", props: {
        user: user_props,
        errors: resource.errors.messages,
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
    params.permit(:full_name, :email, :current_password, :password, :password_confirmation)
  end

  def user_props
    {
      id: resource.id,
      full_name: resource.full_name,
      email: resource.email,
      created_at: resource.created_at.strftime("%d/%m/%Y"),
      last_sign_in_at: resource.last_sign_in_at&.strftime("%d/%m/%Y %H:%M"),
      sign_in_count: resource.sign_in_count,
    }
  end
end
