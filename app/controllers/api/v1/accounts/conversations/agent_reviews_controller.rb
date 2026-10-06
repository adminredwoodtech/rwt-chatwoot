class Api::V1::Accounts::Conversations::AgentReviewsController < Api::V1::Accounts::Conversations::BaseController
  before_action :require_human_actor

  def index
    render json: { review: service.latest }
  rescue Happsea::AgentReviewService::Unavailable
    head :bad_gateway
  end

  def create
    note = params.permit(:note).fetch(:note, '')
    return head :unprocessable_entity unless note.is_a?(String) && note.length <= 2000

    render json: service.submit(note: note), status: :accepted
  rescue Happsea::AgentReviewService::Unavailable
    head :bad_gateway
  end

  private

  def require_human_actor
    head :forbidden unless Current.user.is_a?(User)
  end

  def service
    @service ||= Happsea::AgentReviewService.new(conversation: @conversation, actor: Current.user)
  end
end
