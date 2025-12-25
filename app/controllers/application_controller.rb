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
      permissions: PermissionService.new(current_user, current_project).all_permissions
    }
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :full_name ])
  end

  private

  def current_project
    return nil unless current_user

    current_user.accessible_projects.find_by(id: current_user.current_project_id)
  end
  helper_method :current_project

  def set_current_tenant
    return unless current_user

    project = current_project || auto_assign_project

    if project.nil? && !creating_project?
      redirect_to new_project_path, alert: I18n.t("projects.create_first")
      return
    end

    ActsAsTenant.current_tenant = (project && set_tenant_for_request?) ? project : nil
  end

  def auto_assign_project
    project = current_user.last_accessible_project

    if project.nil? && current_user.global_admin?
      project = Project.create!(name: "Default Project", slug: "default-project-#{SecureRandom.hex(4)}")
      current_user.add_role(:owner, project)
    end

    return nil unless project

    had_previous = current_user.current_project_id.present?
    current_user.update_column(:current_project_id, project.id)

    if had_previous
      flash.clear
      flash.now[:warning] = I18n.t("projects.auto_switched", name: project.name)
    end

    project
  end

  def set_tenant_for_request?
    !(controller_name == "projects" && action_name.in?(%w[index search new create]))
  end

  def creating_project?
    controller_name == "projects" && action_name.in?(%w[new create])
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    action_name = exception.query.to_s.delete_suffix("?")

    # Lookup fallback: {policy}.{action} → default.{action} → default.not_authorized
    specific_key = "pundit.#{policy_name}.#{action_name}"
    action_key = "pundit.default.#{action_name}"
    generic_key = "pundit.default.not_authorized"

    message = I18n.t(specific_key, default: I18n.t(action_key, default: I18n.t(generic_key)))

    redirect_back fallback_location: dashboard_path, alert: message
  end
end
