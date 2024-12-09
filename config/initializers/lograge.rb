#  frozen_string_literal: true

Rails.application.configure do
  # Lograge config taken from
  # https://docs.datadoghq.com/logs/log_collection/ruby/?tab=lograge
  config.lograge.enabled = true

  # This specifies to log in JSON format
  config.lograge.formatter = Lograge::Formatters::Json.new

  ## Disables log coloration
  config.colorize_logging = false

  # Log to a dedicated file
  config.lograge.logger = ActiveSupport::Logger.new(Rails.root.join("log", "#{Rails.env}.log"))

  # This is useful if you want to log query parameters
  config.lograge.custom_options = lambda do |event|
    { ddsource: "ruby",
      params: event.payload[:params].reject { |k| %w[controller action].include? k } }
  end
end
