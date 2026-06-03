# Controls whether full Chatwoot admin UI and routes are exposed.
# When false (default), the fork keeps the light HappSea/Oriental layout.
ADMIN_FEATURES_ENABLED = ENV.fetch('ENABLE_CHATWOOT_ADMIN', 'false') == 'true'
