# spec/spec_helper.rb
require 'rack/test'

require File.expand_path '../../votebot.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Votebot end
end

RSpec.configure do |config|
  config.include RSpecMixin

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
