# Hub SSO Controller
# Provides SSO login URLs for HappSea Hub integration
# Hub signs requests with a shared secret, Chatwoot validates and returns SSO tokens
class Api::V1::HubSsoController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :set_current_user
  before_action :validate_hub_signature

  # POST /api/v1/hub_sso/login
  # Params:
  #   email: user's email address
  #   name: user's display name (optional, used when creating new users)
  #   timestamp: request timestamp (for replay protection)
  #   signature: HMAC-SHA256 signature of "email:timestamp" using shared secret
  def login
    user = find_or_create_user

    if user.nil?
      render json: { error: 'Could not create user' }, status: :unprocessable_entity
      return
    end

    sso_url = user.generate_sso_link
    render json: { url: sso_url }
  end

  private

  def find_or_create_user
    user = User.from_email(params[:email])
    return user if user.present?

    # Create new user with random password (they'll use SSO, not password auth)
    temp_password = "1!aA#{SecureRandom.alphanumeric(12)}"
    user = User.new(
      email: params[:email],
      name: params[:name].presence || params[:email].split('@').first,
      password: temp_password,
      password_confirmation: temp_password
    )
    user.skip_confirmation! # Auto-confirm since they're authenticated via Hub
    user.save!

    # Link user to default account (first account in the system)
    default_account = Account.first
    if default_account
      AccountUser.create!(
        account_id: default_account.id,
        user_id: user.id,
        role: :agent # Default role for SSO users
      )
    end

    user
  rescue StandardError => e
    Rails.logger.error("Hub SSO user creation failed: #{e.message}")
    nil
  end

  def validate_hub_signature
    secret = ENV.fetch('HUB_SSO_SECRET', nil)

    if secret.blank?
      render json: { error: 'Hub SSO not configured' }, status: :service_unavailable
      return
    end

    email = params[:email]
    timestamp = params[:timestamp]
    signature = params[:signature]

    if email.blank? || timestamp.blank? || signature.blank?
      render json: { error: 'Missing required parameters' }, status: :bad_request
      return
    end

    # Check timestamp is within 5 minutes (replay protection)
    request_time = Time.zone.at(timestamp.to_i)
    if (Time.current - request_time).abs > 5.minutes
      render json: { error: 'Request expired' }, status: :unauthorized
      return
    end

    # Validate signature
    expected_signature = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{email}:#{timestamp}")
    unless ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      render json: { error: 'Invalid signature' }, status: :unauthorized
    end
  end
end
