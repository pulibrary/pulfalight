# frozen_string_literal: true
ENV["RACK_ENV"] = "test"
require "coveralls"
require "simplecov"
require "pry"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
)

SimpleCov.coverage_dir(File.join(ENV["CIRCLE_ARTIFACTS"], "coverage")) if ENV["CIRCLE_ARTIFACTS"]
SimpleCov.start do
  add_filter "/config/lando_env.rb"
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
