# frozen_string_literal: true

source "https://rubygems.org"

ruby "~> 2.7.1"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem "rails", "~> 6.0"
# Use Puma as the app server
gem "puma", "~> 5.1"
# Use SCSS for stylesheets
gem "sassc-rails", "~> 2.1"
gem "sassc", "~> 2.4"
gem "sprockets", "< 5"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", "~> 4.2"
# Use CoffeeScript for .coffee assets and views
gem "coffee-rails", "~> 5.0"
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem "jquery-rails"
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem "turbolinks", "~> 5"
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem "jbuilder", "~> 2.10"
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Github
gem "octokit", "~> 4.20"

# Bug tracking with bugsnag
gem "bugsnag"

# Devise and github for login
gem "devise"
gem "omniauth-github"
gem "omniauth-rails_csrf_protection", "~> 0.1"
gem "cancancan"
gem "rails_admin"
gem "paper_trail"

gem "font-awesome-rails"

gem "memoist"

gem "github-markup", require: "github/markup"
gem "redcarpet"
gem "rinku", require: "rails_rinku"

gem "kaminari"

# Custom application configuration
gem "config"

gem "sucker_punch", "~> 2.0"

# Postgres in production for Heroku
group :production do
  gem "pg"
end

group :development, :test do
  gem "sqlite3"
  gem "byebug", platform: :mri
  gem "vcr"
  gem "webmock"
  gem "timecop"
  gem "simplecov"
  gem "simplecov-lcov"
  gem "rspec-rails"
  gem "rspec_junit_formatter" # For CircleCI test reporting
  gem "dotenv-rails"
  gem "database_cleaner"
  gem "email_spec"
  gem "factory_bot_rails"
  gem "faker"
  gem "inch"
  gem "rubocop", require: false
  gem "rubocop-i18n", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rails_config", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-performance", require: false
  gem "yard"
  gem "climate_control"
end

group :development do
  gem "web-console"
  gem "listen", "~> 3.4"
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0"
  gem "letter_opener"
  gem "guard"
  gem "guard-rspec", require: false
  gem "guard-rubocop"
  gem "pry"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
