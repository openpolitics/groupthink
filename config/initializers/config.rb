# frozen_string_literal: true
Dotenv.load!

Config.setup do |config|
  config.const_name = 'Settings'
  config.use_env = true
  config.env_prefix = ''
  config.env_converter = :downcase
  # config.env_parse_values = true

  # Validate presence and type of specific config values. Check https://github.com/dry-rb/dry-validation for details.
  #
  # config.schema do
  #   required(:name).filled
  #   required(:age).maybe(:int?)
  #   required(:email).filled(format?: EMAIL_REGEX)
  # end

end
