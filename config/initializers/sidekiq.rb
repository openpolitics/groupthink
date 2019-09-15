Sidekiq.configure_client do |config|
  config.redis = { size: 5, url: ENV["REDIS_URL"] }
end

Sidekiq.configure_server do |config|
  config.redis = { concurrency: 5, url: ENV["REDIS_URL"] }
end

