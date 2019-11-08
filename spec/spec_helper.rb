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
SimpleCov.start
