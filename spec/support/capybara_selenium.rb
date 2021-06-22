# frozen_string_literal: true

require "capybara/rspec"
require "selenium-webdriver"

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium_chrome_headless
Capybara.default_max_wait_time = 60
