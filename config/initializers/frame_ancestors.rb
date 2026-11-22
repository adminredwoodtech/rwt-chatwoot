# config/ is not on the autoload path, so this file is loaded once at boot.
require Rails.root.join('config/frame_ancestors_middleware')

# Outermost so error pages are covered and later middleware cannot drop the header.
Rails.application.config.middleware.insert_before 0, FrameAncestorsMiddleware
