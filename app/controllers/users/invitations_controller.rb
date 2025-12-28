# frozen_string_literal: true

class Users::InvitationsController < Devise::InvitationsController
  include InertiaRails::Controller

  def new
    render inertia: "auth/accept-invitation", props: {
      invitation_token: params[:invitation_token],
    }
  end

  def edit
    render inertia: "auth/accept-invitation", props: {
      invitation_token: params[:invitation_token],
    }
  end

  protected

  def after_accept_path_for(_resource)
    dashboard_path
  end

  def update_resource_params
    params.permit(:password, :password_confirmation, :invitation_token, :full_name)
  end
end
