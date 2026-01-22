# frozen_string_literal: true

class MissionControlAuthController < ActionController::Base
  include Devise::Controllers::Helpers

  before_action :authenticate_user!
  before_action :require_super_admin!

  private

  def require_super_admin!
    return if current_user&.has_role?(:super_admin)

    if current_user
      redirect_to root_path, alert: I18n.t("authorization.not_authorized")
    else
      redirect_to new_user_session_path
    end
  end
end
