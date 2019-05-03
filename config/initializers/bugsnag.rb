if ENV.fetch("BUGSNAG_API_KEY", nil)
  Bugsnag.configure do |config|
    config.api_key = ENV.fetch("BUGSNAG_API_KEY")
  end
end