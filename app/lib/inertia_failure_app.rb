# frozen_string_literal: true

# Handles Inertia requests on authentication failures (session timeout, locked, unconfirmed).
# Returns 409 + X-Inertia-Location to force a full page reload instead of showing a modal.
class InertiaFailureApp < Devise::FailureApp
  def respond
    inertia_request? ? inertia_location_redirect : super
  end

  private

  def inertia_request?
    request.headers["X-Inertia"].present?
  end

  def inertia_location_redirect
    store_location!
    flash[:alert] = i18n_message if is_flashing_format?

    self.status = 409
    self.location = redirect_url
    response.set_header("X-Inertia-Location", redirect_url)
    self.response_body = ""
  end
end
