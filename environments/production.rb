require 'redis' unless defined?(Redis)

def redis 
  $redis_uri ||= URI.parse(ENV["REDISTOGO_URL"])
  $redis ||= Redis.new(:host => $redis_uri.host, :port => $redis_uri.port, :password => $redis_uri.password)
end