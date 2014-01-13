ENV["REDISTOGO_URL"] = 'redis://localhost'

require 'dotenv'
Dotenv.load

require_relative 'production'