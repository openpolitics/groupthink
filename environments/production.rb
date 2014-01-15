require 'redis' unless defined?(Redis)
require 'twitter'

def redis 
  $redis_uri ||= URI.parse(ENV["REDISTOGO_URL"])
  $redis ||= Redis.new(:host => $redis_uri.host, :port => $redis_uri.port, :password => $redis_uri.password)
end

def twitter
  $twitter ||= Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
    config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
    config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
  end
end