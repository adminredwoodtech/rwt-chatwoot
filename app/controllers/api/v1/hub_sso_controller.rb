# Hub SSO Controller
# Provides SSO login URLs for HappSea Hub integration.
# Hub signs requests with a shared secret. Chatwoot validates the signature and
# returns an SSO URL only for users who already belong to the target account.
class Api::V1::HubSsoController < ApplicationController
  # A timestamp may be up to 5 minutes ahead and stays valid for 5 minutes after,
  # so a consumed signature must be remembered for the full 10-minute lifetime.
  REPLAY_TTL = 11.minutes.to_i
  MEMBERSHIP_ERROR = 'SSO is only available for existing Chatwoot users who belong to this account'.freeze

  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  before_action :validate_hub_signature

  # POST /api/v1/hub_sso/login
  # Params:
  #   email: user's email address
  #   timestamp: request timestamp (must be within 5 minutes)
  #   signature: HMAC-SHA256 signature of "email:timestamp" using shared secret
  #   sso_account_id (optional): account to land on after SSO; membership is required
  #   sso_conversation_id (optional): conversation to deep-link into within that account
  def login
    user = existing_account_member
    return render json: { error: MEMBERSHIP_ERROR }, status: :forbidden if user.nil?

    render json: { url: append_redirect_params(user.generate_sso_link) }
  end

  private

  # Appends optional deep-link query params (sso_account_id, sso_conversation_id)
  # so the Vue login route can land on /app/accounts/:id/conversations/:cid.
  # Account membership is required before the link is issued. Conversation
  # access is still enforced when the page renders.
  def append_redirect_params(sso_url)
    extras = redirect_params
    return sso_url if extras.empty?

    uri = URI.parse(sso_url)
    query = URI.decode_www_form(uri.query.to_s)
    extras.each { |key, value| query << [key, value.to_s] }
    uri.query = URI.encode_www_form(query)
    uri.to_s
  end

  def redirect_params
    {}.tap do |result|
      account_id = sanitized_id(params[:sso_account_id])
      conversation_id = sanitized_id(params[:sso_conversation_id])
      result[:sso_account_id] = account_id if account_id
      result[:sso_conversation_id] = conversation_id if conversation_id
    end
  end

  def sanitized_id(value)
    str = value.to_s.strip
    return nil if str.blank?
    return nil unless str.match?(/\A\d+\z/)

    str
  end

  def existing_account_member
    user = User.from_email(params[:email])
    return if user.blank? || !account_member?(user)

    user
  end

  def account_member?(user)
    account_id = sanitized_id(params[:sso_account_id])
    return false if params[:sso_account_id].present? && account_id.blank?
    return AccountUser.exists?(account_id: account_id, user_id: user.id) if account_id

    user.account_users.exists?
  end

  def validate_hub_signature
    return render_sso_error('Hub SSO not configured', :service_unavailable) if sso_secret.blank?
    return render_sso_error('Missing required parameters', :bad_request) if missing_signature_params?
    return render_sso_error('Request expired', :unauthorized) unless fresh_timestamp?
    return render_sso_error('Invalid signature', :unauthorized) unless valid_signature?

    claim_request!
  end

  def sso_secret
    ENV.fetch('HUB_SSO_SECRET', nil)
  end

  def missing_signature_params?
    params[:email].blank? || params[:timestamp].blank? || params[:signature].blank?
  end

  def fresh_timestamp?
    request_time = Time.zone.at(params[:timestamp].to_i)
    (Time.current - request_time).abs <= 5.minutes
  end

  def valid_signature?
    expected = OpenSSL::HMAC.hexdigest('SHA256', sso_secret, "#{params[:email]}:#{params[:timestamp]}")
    provided = params[:signature].to_s
    return false unless expected.bytesize == provided.bytesize

    ActiveSupport::SecurityUtils.secure_compare(expected, provided)
  end

  # One-time use of a valid signature. The Hub keeps signing "email:timestamp";
  # a captured request cannot be replayed inside the acceptance window.
  def claim_request!
    key = format(Redis::RedisKeys::HUB_SSO_REPLAY_KEY, signature: params[:signature].to_s)
    return true if Redis::Alfred.set(key, '1', nx: true, ex: REPLAY_TTL)

    render_sso_error('Request already used', :unauthorized)
    false
  rescue Redis::BaseError => e
    Rails.logger.error("Hub SSO replay store unavailable: #{e.class}")
    render_sso_error('Hub SSO temporarily unavailable', :service_unavailable)
    false
  end

  def render_sso_error(message, status)
    render json: { error: message }, status: status
  end
end
