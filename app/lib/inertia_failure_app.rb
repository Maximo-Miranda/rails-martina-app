# frozen_string_literal: true

# Custom Devise FailureApp to handle Inertia.js requests properly.
#
# When a user's session expires (timeout) or authentication fails for other reasons
# (locked account, unconfirmed email), Devise's default FailureApp redirects to the
# login page with an HTML response. However, Inertia.js makes XHR requests and expects
# either an Inertia response or a special 409 Conflict with X-Inertia-Location header
# to force a full page reload.
#
# Without this custom handler, Inertia would display the HTML response in a modal dialog
# instead of properly redirecting the user to the login page.
#
# @see https://github.com/heartcombo/devise/wiki/How-To:-Redirect-to-a-specific-page-when-the-user-can-not-be-authenticated
# @see https://inertiajs.com/redirects#external-redirects
class InertiaFailureApp < Devise::FailureApp
  # Override the respond method to detect Inertia requests and return
  # a 409 Conflict response with X-Inertia-Location header.
  #
  # This forces Inertia to perform a full page reload to the redirect URL,
  # which properly displays the login page with flash messages.
  def respond
    if inertia_request?
      inertia_location_redirect
    else
      super
    end
  end

  private

  # Check if the current request is an Inertia request by looking for the X-Inertia header.
  #
  # @return [Boolean] true if this is an Inertia XHR request
  def inertia_request?
    request.headers["X-Inertia"].present?
  end

  # Respond with a 409 Conflict status and X-Inertia-Location header.
  #
  # Inertia.js will intercept this response and perform a full page reload
  # to the URL specified in X-Inertia-Location, preserving flash messages
  # that were set by Devise.
  #
  # The redirect_url is automatically calculated by Devise::FailureApp based on
  # the failure reason:
  # - timeout/unauthenticated → new_user_session_url
  # - locked → new_user_unlock_url
  # - unconfirmed → new_user_confirmation_url
  def inertia_location_redirect
    # Store the location and set flash messages just like the normal redirect flow
    store_location!
    flash[:alert] = i18n_message if is_flashing_format?

    # Return 409 Conflict with X-Inertia-Location header
    # This tells Inertia to do a full page reload to this URL
    self.status = 409
    self.location = redirect_url
    response.set_header("X-Inertia-Location", redirect_url)
    self.response_body = ""
  end
end
