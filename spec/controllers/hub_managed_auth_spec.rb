require 'rails_helper'

describe 'Hub-managed messaging authentication', type: :request do
  around do |example|
    with_modified_env(HAPPSEA_HUB_URL: 'https://hub.example.com', HUB_RECOVERY_USERNAME: nil, HUB_RECOVERY_PASSWORD: nil) { example.run }
  end

  it 'renders a non-login gate for direct login, reset and signup routes' do
    ['/', '/app/login', '/app/login/sso', '/app/auth/signup', '/app/auth/reset/password'].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('happsea:auth-required', 'https://hub.example.com')
      expect(response.body).not_to include('vite_javascript', 'email_input', 'chatwootConfig')
      expect(response.headers['Cache-Control']).to include('no-store')
    end
  end

  it 'allows the one-time SSO entry without rendering the password gate' do
    get '/app/login', params: { email: 'advisor@example.com', sso_auth_token: 'example' }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('happseaHubUrl:', 'https://hub.example.com/images/happsea_in_text.png')
    expect(response.body).not_to include("type: 'happsea:auth-required'")
  end

  it 'keeps recovery disabled by default' do
    get '/hub-recovery'
    expect(response).to have_http_status(:not_found)
  end

  it 'requires separate credentials for recovery before showing the ordinary login form' do
    with_modified_env(HUB_RECOVERY_USERNAME: 'operator', HUB_RECOVERY_PASSWORD: 'recovery-test-password') do
      get '/hub-recovery'
      expect(response).to have_http_status(:unauthorized)
      get '/hub-recovery', headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('operator', 'wrong') }
      expect(response).to have_http_status(:unauthorized)
      get '/hub-recovery',
          headers: { 'HTTP_AUTHORIZATION' => ActionController::HttpAuthentication::Basic.encode_credentials('operator', 'recovery-test-password') }
      expect(response).to redirect_to('/app/login')
      follow_redirect!
      expect(response.body).to include('hubRecovery: true')
      travel_to 16.minutes.from_now do
        get '/app/login'
        expect(response.body).to include('happsea:auth-required')
      end
    end
  end
end
