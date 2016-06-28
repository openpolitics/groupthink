source "https://rubygems.org"

ruby "2.3.1"

gem "rake"
gem "sinatra"
gem "github_api"
gem "twitter"
gem "sinatra-partial"
gem "bugsnag"
gem "faraday_middleware"

group :development, :production do
  gem "redis"
end  

group :test do
  gem "mock_redis"
  gem "vcr"
  gem "webmock"
  gem "timecop"
end  

group :development do
  gem "travis"
end  

group :development, :test do
  gem "rspec"
  gem "rack-test"
  gem "dotenv"
end