# frozen_string_literal: true

Dotenv.load!

Config.setup do |config|
  config.const_name = "Settings"
  config.use_env = true
  config.env_prefix = ""
  config.env_converter = :downcase
  # config.env_parse_values = true

  # Validate presence and type of specific config values.
  # Check https://github.com/dry-rb/dry-validation for details.
  config.schema do
    required(:max_age)
    required(:min_age)
    required(:pass_threshold)
    required(:yes_weight)
    required(:no_weight)
    required(:block_weight)
    required(:block_threshold)
  end
end
