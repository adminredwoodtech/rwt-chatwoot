require 'rails_helper'

describe 'Hub SSO', type: :request do
  let(:secret) { 'hub-sso-test-secret' }
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, email: 'advisor@example.com') }
  let(:timestamp) { Time.current.to_i }
  let(:replay_store) { {} }

  around do |example|
    with_modified_env(HUB_SSO_SECRET: secret, FRONTEND_URL: 'https://chat.example.com') { example.run }
  end

  before do
    allow(Redis::Alfred).to receive(:set) do |key, value, nx: false, ex: nil|
      next false if nx && replay_store.key?(key)

      replay_store[key] = { value: value, ex: ex }
      true
    end
  end

  def signed_params(email_address, stamp = timestamp, **extra)
    {
      email: email_address,
      timestamp: stamp,
      signature: OpenSSL::HMAC.hexdigest('SHA256', secret, "#{email_address}:#{stamp}")
    }.merge(extra)
  end

  def post_login(params)
    post '/api/v1/hub_sso/login', params: params, as: :json
  end

  it 'returns an SSO url for an existing account member' do
    post_login(signed_params(user.email))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['url']).to include('https://chat.example.com/app/login', 'sso_auth_token=', 'advisor%40example.com')
  end

  it 'appends a deep link when the user belongs to the requested account' do
    post_login(signed_params(user.email, sso_account_id: account.id, sso_conversation_id: 42))

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body['url']).to include("sso_account_id=#{account.id}", 'sso_conversation_id=42')
  end

  it 'does not provision a user or an account membership' do
    expect do
      post_login(signed_params('stranger@example.com', name: 'New Person'))
    end.not_to(change { [User.count, AccountUser.count] })

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body['error']).to eq(Api::V1::HubSsoController::MEMBERSHIP_ERROR)
  end

  it 'refuses an existing user who belongs to no account' do
    orphan = create(:user, email: 'orphan@example.com')

    post_login(signed_params(orphan.email, name: 'Orphan'))

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body['error']).to eq(Api::V1::HubSsoController::MEMBERSHIP_ERROR)
  end

  it 'refuses a member of a different account' do
    other_account = create(:account)

    post_login(signed_params(user.email, sso_account_id: other_account.id))

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body['error']).to eq(Api::V1::HubSsoController::MEMBERSHIP_ERROR)
  end

  it 'rejects a signed request that is presented twice' do
    params = signed_params(user.email)

    post_login(params)
    expect(response).to have_http_status(:ok)

    post_login(params)
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body['error']).to eq('Request already used')
  end

  it 'rejects an expired timestamp' do
    post_login(signed_params(user.email, 10.minutes.ago.to_i))

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body['error']).to eq('Request expired')
  end

  it 'rejects a signature of the wrong value or length' do
    bad = signed_params(user.email).merge(signature: 'a' * 64)
    post_login(bad)
    expect(response).to have_http_status(:unauthorized)

    post_login(signed_params(user.email).merge(signature: 'short'))
    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body['error']).to eq('Invalid signature')
  end

  it 'fails closed when the shared secret is missing' do
    with_modified_env(HUB_SSO_SECRET: nil) do
      post_login(signed_params(user.email))

      expect(response).to have_http_status(:service_unavailable)
      expect(response.parsed_body['error']).to eq('Hub SSO not configured')
    end
  end

  it 'rejects a request without the signed fields' do
    post_login(email: user.email)

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body['error']).to eq('Missing required parameters')
  end

  it 'fails closed when the replay store is unavailable' do
    allow(Redis::Alfred).to receive(:set).and_raise(Redis::CannotConnectError, 'down')

    post_login(signed_params(user.email))

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body['error']).to eq('Hub SSO temporarily unavailable')
  end
end
