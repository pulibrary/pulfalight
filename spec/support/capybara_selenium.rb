# frozen_string_literal: true

require "capybara/rspec"
require "selenium-webdriver"

Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 60
Capybara.javascript_driver =
  if ENV["RUN_IN_BROWSER"] == "true"
    :selenium_chrome
  else
    :selenium_chrome_headless
  end
