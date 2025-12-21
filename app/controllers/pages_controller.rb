class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :landing ]
  layout "public"
  def landing
  end
end
