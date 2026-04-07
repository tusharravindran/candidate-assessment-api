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
  end
end
