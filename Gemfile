# frozen_string_literal: true
source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.1"
# Use Puma as the app server
gem "puma", "~> 5.6"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Terser as compressor for JavaScript assets
gem "terser"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'mini_racer', platforms: :ruby

# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 4.2"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.5"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", ">= 1.1.0", require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "benchmark-ips"
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 5.0"
  gem "ruby-prof"
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "bcrypt_pbkdf"
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "pry-byebug"
  gem "pry-rails"
  gem "web-console", ">= 3.3.0"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "capistrano", "~> 3.10", require: false
  gem "capistrano-passenger", require: false
  gem "capistrano-rails", "~> 1.4", require: false
  gem "capistrano-rails-console"
  gem "ed25519"
  gem "factory_bot_rails"
  gem "foreman"
  gem "solargraph"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end

group :test do
  gem "axe-core-api", "4.0.0"
  gem "axe-core-rspec", "4.0.0"
  gem "capybara", ">= 3.18"
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

gem "archivesspace-client"
gem "arclight", git: "https://github.com/projectblacklight/arclight.git"
gem "blacklight", "7.29.0"
gem "blacklight_dynamic_sitemap"
gem "blacklight_range_limit", "~> 7.1"
gem "bootstrap", "~> 4.6"
gem "change_the_subject"
gem "devise", ">= 4.7.1"
gem "devise-guests", "~> 0.6"
gem "honeybadger", "~> 4.0"
gem "jquery-rails"
gem "omniauth-cas"
gem "pg"
gem "popper_js"
gem "rsolr", ">= 1.0", "< 3"
gem "rubytree"
gem "rubyzip", ">= 1.3.0"
gem "sidekiq", "~> 6.5"
gem "twitter-typeahead-rails", "0.11.1.pre.corejavascript"
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "whenever", require: false

gem "dotenv-rails", groups: [:development, :test]

gem "email_validator"
gem "faraday"
gem "simple_form"

# Added for Ruby 3.1 support
gem "matrix"
gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false
gem "strscan", "3.0.1"

gem "vite_rails", "~> 3.0"

gem "debug", "~> 1.8"
