class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  inertia_share do
  {
    flash: flash.to_hash,
    current_user: current_user&.as_json(only: [ :id, :email, :full_name ])
  }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :full_name ])
  end
end
