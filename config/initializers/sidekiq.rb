Sidekiq.configure_client do |config|
  config.redis = { size: 5, url: ENV["REDIS_URL"] }
end
