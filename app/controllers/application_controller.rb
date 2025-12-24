class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern if Rails.env.production?

  include InertiaRails::Controller
  include Devise::Controllers::Helpers
  include Pundit::Authorization
  include Pagy::Method

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_current_tenant, unless: :devise_controller?

  set_current_tenant_through_filter

  # Translations cached on the client with once
  inertia_share t: InertiaRails.once { I18n.t("frontend").deep_stringify_keys }

  inertia_share do
    {
      flash: flash.to_hash,
      current_user: current_user&.as_json(only: %i[id email full_name current_project_id]),
      current_project: current_project&.as_json(only: %i[id name slug]),
      permissions: {
        can_manage_users: current_user && policy(User).show_menu?
      }
    }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :full_name ])
  end

  private

  def current_project
    @current_project ||= current_user&.current_project&.kept? ? current_user.current_project : nil
  end
  helper_method :current_project

  def set_current_tenant
    return unless current_user

    project = current_project || current_user.accessible_projects.first

    if project
      if current_user.current_project_id != project.id
        current_user.update_column(:current_project_id, project.id)
      end
      ActsAsTenant.current_tenant = project
    elsif !creating_project?
      # Clear current_project_id if it pointed to a deleted project
      current_user.update_column(:current_project_id, nil) if current_user.current_project_id
      redirect_to new_project_path, alert: I18n.t("projects.create_first")
    end
  end

  def creating_project?
    controller_name == "projects" && action_name.in?(%w[new create])
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    action_name = exception.query.to_s.delete_suffix("?")

    # Intenta buscar un mensaje específico para policy + action, luego solo action, luego default
    message = I18n.t(
      "pundit.#{policy_name}.#{action_name}",
      default: I18n.t(
        "pundit.default.#{action_name}",
        default: I18n.t("pundit.default.not_authorized")
      )
    )

    redirect_back fallback_location: dashboard_path, alert: message
  end
end
