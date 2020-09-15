# frozen_string_literal: true
RSpec.configure do |config|
  config.include Capybara::RSpecMatchers, type: :request
end
