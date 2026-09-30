module HubManagedAuth
  extend ActiveSupport::Concern

  private

  def hub_url
    value = ENV.fetch('HAPPSEA_HUB_URL', '').presence
    return unless value

    uri = URI.parse(value)
    raise ArgumentError, 'HAPPSEA_HUB_URL must be an HTTP(S) origin' unless
      %w[http https].include?(uri.scheme) && uri.host && [uri.userinfo, uri.query, uri.fragment].all?(&:nil?) && ['', '/'].include?(uri.path)

    value.delete_suffix('/')
  end

  def hub_recovery?
    session[:hub_recovery_until].to_i > Time.current.to_i
  end

  def guard_hub_auth
    return unless hub_url

    response.headers['Cache-Control'] = 'no-store'
    return if hub_recovery?
    return unless hub_auth_path?
    return if hub_sso_entry?

    @hub_url = hub_url
    render 'dashboard/hub_auth', layout: false
  end

  def hub_auth_path?
    request.path == '/' || request.path.match?(%r{\A/app/(?:login|auth)(?:/|\z)})
  end

  def hub_sso_entry?
    request.path == '/app/login' && params[:email].present? && params[:sso_auth_token].present?
  end
end
