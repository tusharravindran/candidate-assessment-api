require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.public_file_server.enabled = ENV.fetch("RAILS_SERVE_STATIC_FILES", "true") == "true"
  config.log_level = :info
  config.log_tags = [:request_id]
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    pool_size: ENV.fetch("RAILS_MAX_THREADS", 5).to_i
  }
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
  config.force_ssl = false # Render handles SSL termination
  config.active_job.queue_adapter = :sidekiq
  config.x.frontend_url = ENV.fetch("FRONTEND_URL", "https://candidate-assessment-web.vercel.app")
  config.log_formatter = ::Logger::Formatter.new
  config.logger = ActiveSupport::Logger.new($stdout) if ENV["RAILS_LOG_TO_STDOUT"].present?
end
