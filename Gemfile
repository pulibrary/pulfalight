# frozen_string_literal: true
source "https://gem.coop"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gem "archivesspace-client"
gem "arclight", github: "pulibrary/arclight", branch: "v0.5.0-rails-7"
gem "blacklight", "~> 7.34"
gem "blacklight_dynamic_sitemap"
gem "blacklight_range_limit", "~> 7.1"
gem "bootsnap", ">= 1.1.0", require: false
gem "bootstrap", "~> 4.6"
gem "change_the_subject"
gem "connection_pool", "< 3"
gem "datadog", require: "datadog/auto_instrument"
gem "devise", ">= 4.7.1"
gem "devise-guests", "~> 0.6"
gem "dotenv-rails", groups: [:development, :test]
gem "email_validator"
gem "faraday"
# Pinning to 12.4.0 due to Rails 7.1 compatibility issue in 12.4.1
gem "health-monitor-rails", "~> 12.4"
gem "honeybadger"
gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "lograge"
gem "msgpack"
gem "omniauth", "2.1.2"
gem "omniauth-cas", "3.0.0"
gem "open3"
gem "pg"
gem "popper_js"
gem "puma", "~> 5.6"
gem "rails", "~> 7.2.0"
gem "redis-namespace"
gem "rsolr", ">= 1.0", "< 3"
gem "rubytree"
gem "rubyzip", ">= 1.3.0"
gem "sassc-rails"
gem "sass-rails", "~> 5.0"
gem "sidekiq", "~> 6.5"
gem "simple_form"
gem "terser"
gem "twitter-typeahead-rails", "0.11.1.pre.corejavascript"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "vite_rails"
gem "whenever", require: false

group :development, :test do
  gem "benchmark-ips"
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "debug", "~> 1.8"
  gem "rails-controller-testing"
  gem "rspec-rails"
end

group :development do
  gem "bcrypt_pbkdf"
  gem "capistrano", "~> 3.10", require: false
  gem "capistrano-passenger", require: false
  gem "capistrano-rails", "~> 1.4", require: false
  gem "capistrano-rails-console"
  gem "ed25519"
  gem "factory_bot_rails"
  gem "foreman"
  gem "listen"
  gem "pry-byebug"
  gem "pry-rails"
  gem "solargraph"
  gem "spring"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "axe-core-api", "4.0.0"
  gem "axe-core-rspec", "4.0.0"
  gem "capybara", ">= 3.18"
  gem "openssl" # fix cert error with webmock
  gem "rspec_junit_formatter"
  gem "simplecov", require: false
  gem "timecop"
  gem "webdrivers"
  gem "webmock"
end

group :development, :test do
  gem "bixby", "~> 4.0"
  gem "database_cleaner"
end
