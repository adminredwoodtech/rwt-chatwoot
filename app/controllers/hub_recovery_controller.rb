# Disabled unless separate HTTP Basic credentials are set. This only unlocks
# the normal login form; it never authenticates a messaging user.
class HubRecoveryController < ActionController::Base # rubocop:disable Rails/ApplicationController -- Public recovery entry, like DashboardController
  def show
    response.headers['Cache-Control'] = 'no-store'
    username = ENV.fetch('HUB_RECOVERY_USERNAME', '')
    password = ENV.fetch('HUB_RECOVERY_PASSWORD', '')
    return head :not_found if username.blank? || password.blank?

    authenticated = authenticate_with_http_basic do |given_user, given_password|
      ActiveSupport::SecurityUtils.secure_compare(given_user, username) &
        ActiveSupport::SecurityUtils.secure_compare(given_password, password)
    end
    unless authenticated
      request_http_basic_authentication('Messaging administrator recovery')
      return
    end

    session[:hub_recovery_until] = 15.minutes.from_now.to_i
    redirect_to '/app/login'
  end
end
