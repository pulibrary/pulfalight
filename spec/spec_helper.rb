# frozen_string_literal: true
ENV["RACK_ENV"] = "test"
require "simplecov"
require "pry"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter
  ]
)

SimpleCov.coverage_dir(File.join(ENV["CIRCLE_ARTIFACTS"], "coverage")) if ENV["CIRCLE_ARTIFACTS"]
SimpleCov.start "rails" do
  add_filter "app/mailers/application_mailer.rb"
  add_filter "config"
  add_filter "spec"
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
