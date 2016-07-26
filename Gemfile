source "https://rubygems.org"

ruby "2.3.1"

gem "rake"
gem "sinatra"
gem "octokit", "~> 4.0"
gem "sinatra-partial"
gem "bugsnag"
gem "faraday_middleware"
gem "sinatra-activerecord"

group :development, :production do
  gem "redis"
end  

group :production do
  gem "pg"
end  

group :test do
  gem "mock_redis"
  gem "vcr"
  gem "webmock"
  gem "timecop"
  gem "coveralls"
end  

group :development do
  gem "travis"
end  

group :development, :test do
  gem "sqlite3"
  gem "rspec"
  gem "rack-test"
  gem "dotenv"
  gem "byebug"
  gem "database_cleaner"
end