Rails.application.configure do
  config.cache_classes = true

  config.i18n.default_locale = :ru

  config.eager_load = true

  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = true

  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass

  config.assets.compile = true

  config.log_level = :warn

  config.log_tags = [ :request_id ]

  config.action_mailer.perform_caching = false
  config.action_mailer.default_options = {from: 'info@easy-ts.ru'}
  config.action_mailer.default_url_options = { host: 'easy-ts.ru' }

  config.i18n.fallbacks = true

  config.active_support.deprecation = :notify

  config.log_formatter = ActiveSupport::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false
end
