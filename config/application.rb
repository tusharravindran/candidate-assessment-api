require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)

module CandidateAssessmentApi
  class Application < Rails::Application
    config.load_defaults 7.1
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq
    config.time_zone = "UTC"
    config.i18n.default_locale = :en

    # RailsAdmin is a full-stack engine mounted inside an API-only app.
    # It needs cookies, sessions, and flash — none of which ship with api_only.
    # We add them back here so the /admin engine has what it needs without
    # affecting API endpoints (they ignore cookies and sessions entirely).
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore,
                          key: "_candidate_assessment_admin_session",
                          secure: Rails.env.production?,
                          same_site: :lax,
                          httponly: true
    config.middleware.use ActionDispatch::Flash
    config.middleware.use Rack::MethodOverride

    # Re-enable assets pipeline for RailsAdmin in an API-only app.
    config.assets.enabled = true
  end
end
