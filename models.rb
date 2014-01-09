require 'redis'

if ENV['RACK_ENV'] != "production" 
  ENV["REDISTOGO_URL"] = 'redis://localhost'
end

uri = URI.parse(ENV["REDISTOGO_URL"])
REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

require_relative 'models/pull_request'