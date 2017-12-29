source 'https://rubygems.org'

ruby "2.4.2"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '~> 4.1'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Github 
gem "octokit", "~> 4.8"

# Bug tracking with bugsnag
gem "bugsnag"

# Devise and github for login
gem "devise"
gem "omniauth-github"

gem "font-awesome-rails"

gem "memoist"

gem 'github-markup', require: 'github/markup'
gem 'redcarpet'
gem 'rinku', require: 'rails_rinku'

gem 'kaminari'

# Postgres in production for Heroku
group :production do
  gem "pg"
  gem "sidekiq"
end  

group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
  gem "vcr"
  gem "webmock"
  gem "timecop"
  gem "coveralls"
  gem "rspec-rails"
  gem "dotenv-rails"
  gem "database_cleaner"
  gem "email_spec"
  gem "factory_girl_rails"
  gem "faker"
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0'
  gem "letter_opener"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
