require 'net/http'

# Server-only adapter: the dedicated review credential never reaches the browser.
class Happsea::AgentReviewService
  class Unavailable < StandardError; end

  def initialize(conversation:, actor:)
    @conversation = conversation
    @actor = actor
  end

  def latest
    data = request(:get, "?conversation_id=#{@conversation.display_id}&limit=1")
    review = data.fetch('reviews', []).first
    return nil unless review && review['chatwootAccountId'] == @conversation.account_id

    { id: review['id'], status: review.dig('run', 'status') }
  end

  def submit(note:)
    request(:post, '', {
              conversation_id: @conversation.display_id,
              account_id: @conversation.account_id,
              note: note
            }).slice('id', 'duplicate')
  end

  private

  def request(method, suffix, body = nil)
    base = ENV.fetch('HAPPSEA_BRIDGE_INTERNAL_URL', '').chomp('/')
    token = ENV.fetch('AGENT_REVIEW_API_TOKEN', '')
    raise Unavailable, 'Review service is not configured' if base.blank? || token.blank?

    uri = URI("#{base}/api/agent-reviews#{suffix}")
    message = method == :post ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
    message['Authorization'] = "Bearer #{token}"
    message['Content-Type'] = 'application/json'
    message['X-Happsea-Actor'] = "chatwoot:#{@actor.id}"
    message.body = body.to_json if body
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 5, read_timeout: 55) do |http|
      http.request(message)
    end
    raise Unavailable, "Review service returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError, IOError, SystemCallError, Timeout::Error, SocketError, URI::InvalidURIError => e
    raise Unavailable, "Review service unavailable (#{e.class.name})"
  end
end
