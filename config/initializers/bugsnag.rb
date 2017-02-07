if ENV["BUGSNAG_API_KEY"]
  Bugsnag.configure do |config|
    config.api_key = ENV["BUGSNAG_API_KEY"]
  end
end