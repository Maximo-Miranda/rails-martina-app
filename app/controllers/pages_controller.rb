class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :landing ]
  layout "public"

  def landing
    # Si el usuario está autenticado, redirigir al dashboard
    redirect_to dashboard_path if user_signed_in?
  end
end
