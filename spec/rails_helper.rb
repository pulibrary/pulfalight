# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require "spec_helper"
require File.expand_path("../../config/environment", __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "factory_bot_rails"
require "axe-rspec"

ActiveRecord::Migration.maintain_test_schema!

Dir[Rails.root.join("spec", "support", "**", "*.rb")].each { |f| require f }

ActiveJob::Base.queue_adapter = :inline

RSpec.configure do |config|
  # Note that as of Rails 7, "fixture_path" is deprecated. You have to call "fixture_paths.first" instead.
  config.fixture_paths = []
  config.fixture_paths << Rails.root.join("spec", "fixtures").to_s

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.before(:suite) do
    DatabaseCleaner.start
  ensure
    DatabaseCleaner.clean
  end

  config.include Capybara::DSL
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include FactoryBot::Syntax::Methods

  config.infer_spec_type_from_file_location!
end
