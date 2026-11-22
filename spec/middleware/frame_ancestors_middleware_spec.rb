require 'rails_helper'

describe FrameAncestorsMiddleware, type: :request do
  let(:hub_origin) { 'https://hub.example.com' }

  def content_security_policy
    response.headers['Content-Security-Policy']
  end

  describe '.policy' do
    it 'limits production to self when no origin is configured' do
      with_modified_env(CHATWOOT_FRAME_ANCESTORS: nil, FRAME_ANCESTORS: nil, HAPPSEA_HUB_URL: nil) do
        expect(described_class.policy(production: true)).to eq("frame-ancestors 'self'")
        expect(described_class.policy(production: false)).to be_nil
      end
    end

    it 'uses the configured hub origin and ignores wildcards' do
      with_modified_env(CHATWOOT_FRAME_ANCESTORS: "#{hub_origin} *", FRAME_ANCESTORS: 'https://other.example.com', HAPPSEA_HUB_URL: nil) do
        expect(described_class.policy(production: false)).to eq("frame-ancestors 'self' #{hub_origin}")
      end
    end

    it 'falls back to FRAME_ANCESTORS and then HAPPSEA_HUB_URL' do
      with_modified_env(CHATWOOT_FRAME_ANCESTORS: nil, FRAME_ANCESTORS: 'https://legacy.example.com/', HAPPSEA_HUB_URL: hub_origin) do
        expect(described_class.policy(production: false)).to eq("frame-ancestors 'self' https://legacy.example.com")
      end

      with_modified_env(CHATWOOT_FRAME_ANCESTORS: nil, FRAME_ANCESTORS: nil, HAPPSEA_HUB_URL: "#{hub_origin}/") do
        expect(described_class.policy(production: false)).to eq("frame-ancestors 'self' #{hub_origin}")
      end
    end
  end

  it 'sends the hub frame-ancestors policy on application responses and drops X-Frame-Options' do
    with_modified_env(CHATWOOT_FRAME_ANCESTORS: hub_origin, HAPPSEA_HUB_URL: nil) do
      get '/health'

      expect(response).to have_http_status(:ok)
      expect(content_security_policy).to eq("frame-ancestors 'self' #{hub_origin}")
      expect(response.headers['X-Frame-Options']).to be_nil
    end
  end

  it 'sends the same policy on API responses' do
    with_modified_env(CHATWOOT_FRAME_ANCESTORS: hub_origin, HAPPSEA_HUB_URL: nil) do
      get '/api/v1/profile'

      expect(response).to have_http_status(:unauthorized)
      expect(content_security_policy).to eq("frame-ancestors 'self' #{hub_origin}")
    end
  end

  it 'does not replace the public widget embedding headers' do
    app = lambda do |_env|
      [200, { 'X-Frame-Options' => 'SAMEORIGIN' }, ['widget']]
    end

    with_modified_env(CHATWOOT_FRAME_ANCESTORS: hub_origin, HAPPSEA_HUB_URL: nil) do
      _status, headers, = described_class.new(app).call(Rack::MockRequest.env_for('/widget'))

      expect(headers['Content-Security-Policy']).to be_nil
      expect(headers['X-Frame-Options']).to eq('SAMEORIGIN')
    end
  end

  it 'keeps same-origin framing when production has no hub origin' do
    app = lambda do |_env|
      [200, { 'X-Frame-Options' => 'SAMEORIGIN' }, ['ok']]
    end

    allow(Rails.env).to receive(:production?).and_return(true)
    with_modified_env(CHATWOOT_FRAME_ANCESTORS: nil, FRAME_ANCESTORS: nil, HAPPSEA_HUB_URL: nil) do
      _status, headers, = described_class.new(app).call(Rack::MockRequest.env_for('/app/login'))

      expect(headers['content-security-policy']).to eq("frame-ancestors 'self'")
      expect(headers['X-Frame-Options']).to eq('SAMEORIGIN')
    end
  end
end
