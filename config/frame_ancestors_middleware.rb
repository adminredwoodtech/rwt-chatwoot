# Adds a frame-ancestors Content-Security-Policy to application responses.
# Production always sends one. When a Hub origin is configured, that origin
# (and 'self') may frame the app and X-Frame-Options is omitted so the Hub
# iframe still works. Otherwise framing is limited to 'self'.
#
# The public website widget and help center keep their own embedding rules.
class FrameAncestorsMiddleware
  PUBLIC_EMBED_PATH = %r{\A/(?:widget(?:/|\z)|widget_tests(?:/|\z)|hc/)}
  HTTP_SCHEMES = %w[http https].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    apply_frame_ancestors(headers, env)
    [status, headers, body]
  end

  def self.policy(production: Rails.env.production?)
    ancestors = configured_ancestors
    return if ancestors.empty? && !production

    "frame-ancestors #{(["'self'"] + ancestors).uniq.join(' ')}"
  end

  def self.configured_ancestors
    explicit = ENV['CHATWOOT_FRAME_ANCESTORS'].presence || ENV['FRAME_ANCESTORS'].presence
    return parse_list(explicit) if explicit

    origin = origin_for(ENV.fetch('HAPPSEA_HUB_URL', nil))
    origin ? [origin] : []
  end

  private

  def apply_frame_ancestors(headers, env)
    return if env['PATH_INFO'].to_s.match?(PUBLIC_EMBED_PATH)

    directive = self.class.policy
    return if directive.blank? || frame_ancestors?(headers)

    set_header(headers, 'content-security-policy', merge_policy(header_value(headers, 'content-security-policy'), directive))
    external_ancestor? ? delete_header(headers, 'x-frame-options') : ensure_same_origin(headers)
  end

  def external_ancestor?
    self.class.configured_ancestors.any?
  end

  def frame_ancestors?(headers)
    header_value(headers, 'content-security-policy').to_s.match?(/frame-ancestors/i)
  end

  def merge_policy(existing, directive)
    existing.present? ? "#{existing}; #{directive}" : directive
  end

  def ensure_same_origin(headers)
    return if header_value(headers, 'x-frame-options').present?

    set_header(headers, 'x-frame-options', 'SAMEORIGIN')
  end

  def header_value(headers, name)
    headers.find { |key, _value| key.to_s.casecmp(name).zero? }&.last
  end

  def delete_header(headers, name)
    headers.keys.select { |key| key.to_s.casecmp(name).zero? }.each { |key| headers.delete(key) }
  end

  def set_header(headers, name, value)
    delete_header(headers, name)
    headers[name] = value
  end

  class << self
    private

    def parse_list(raw)
      raw.to_s.split(/[\s,]+/).filter_map { |token| origin_for(token) }
    end

    def origin_for(value)
      uri = URI.parse(value.to_s.strip)
      return unless HTTP_SCHEMES.include?(uri.scheme) && safe_host?(uri.host) && uri.userinfo.blank?

      format_origin(uri)
    rescue URI::InvalidURIError
      nil
    end

    def safe_host?(host)
      return false if host.blank? || host.include?('*')

      host.match?(/\A(?:localhost|[a-z0-9.-]+|\d{1,3}(?:\.\d{1,3}){3}|[a-f0-9:]+)\z/i)
    end

    def format_origin(uri)
      default_port = uri.scheme == 'https' ? 443 : 80
      host = uri.host.downcase
      uri.port == default_port ? "#{uri.scheme}://#{host}" : "#{uri.scheme}://#{host}:#{uri.port}"
    end
  end
end
