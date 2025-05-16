# frozen_string_literal: true
# rubocop:disable Metrics/BlockLength
Rails.application.config.after_initialize do
  # Adds a patch a check is always critical if it's filtered for, otherwise fall
  # back to configured value.
  class HealthMonitor::Providers::Base
    def critical
      return true if request && request.parameters["providers"].present?
      configuration.critical
    end
  end

  HealthMonitor.configure do |config|
    config.cache

    config.add_custom_provider(CheckOverrides::Redis).configure do |provider_config|
      provider_config.critical = false
    end
    config.solr.configure do |c|
      c.url = Blacklight.default_index.connection.uri.to_s
      c.collection = Blacklight.default_index.connection.uri.path.split("/").last
    end
    config.add_custom_provider(SmtpStatus).configure do |provider_config|
      provider_config.critical = false
    end
    config.file_absence.configure do |file_config|
      file_config.filename = "public/remove-from-nginx"
    end

    # monitor all the queues for latency
    # The gem also comes with some additional default monitoring,
    # e.g. it ensures that there are running workers
    config.sidekiq.configure do |sidekiq_config|
      sidekiq_config.critical = false
      sidekiq_config.latency = 2.days
      sidekiq_config.queue_size = 1_000_000
      sidekiq_config.maximum_amount_of_retries = 17
      sidekiq_config.add_queue_configuration("high", latency: 2.days, queue_size: 1_000_000)
      sidekiq_config.add_queue_configuration("mailers", latency: 1.day, queue_size: 100)
      sidekiq_config.add_queue_configuration("low", latency: 2.days, queue_size: 1_000_000)
      sidekiq_config.add_queue_configuration("super_low", latency: 2.days, queue_size: 1_000_000)
    end

    # Make this health check available at /health
    config.path = :health

    config.error_callback = proc do |e|
      Rails.logger.error "Health check failed with: #{e.message}" unless e.is_a?(HealthMonitor::Providers::FileAbsenceException)
    end
  end
end
# rubocop:enable Metrics/BlockLength
