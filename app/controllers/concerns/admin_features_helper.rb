# frozen_string_literal: true

module AdminFeaturesHelper
  def admin_features_enabled?
    ADMIN_FEATURES_ENABLED
  end

  def ensure_admin_features_enabled!
    return if admin_features_enabled?

    render json: { error: 'Admin features disabled' }, status: :forbidden
  end
end
