# frozen_string_literal: true
require_relative "boot"

require "rails/all"
require_relative "lando_env"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Pulfalight
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.default_url_options = {
      host: ENV.fetch("APPLICATION_HOST", "localhost"),
      protocol: ENV.fetch("APPLICATION_HOST_PROTOCOL", "http")
    }
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # load overrides
    config.to_prepare do
      Dir.glob(Rails.root.join("app", "**", "*_override*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
  end
end
