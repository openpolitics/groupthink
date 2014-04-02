# spec/spec_helper.rb
require 'rack/test'
require 'database_cleaner'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/cassettes'
  c.hook_into :webmock
  c.filter_sensitive_data('<GITHUB_OAUTH_TOKEN>') { ENV['GITHUB_OAUTH_TOKEN'] }
  c.configure_rspec_metadata!
  c.default_cassette_options = { :record => :once }
end

ENV["RACK_ENV"] = "test"

require File.expand_path '../../votebot.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() Votebot end
end

DatabaseCleaner.strategy = :truncation

RSpec.configure do |config|
  config.include RSpecMixin

  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.treat_symbols_as_metadata_keys_with_true_values = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

end

def load_fixture(filename)
  File.read(File.join(File.dirname(__FILE__), 'fixtures', filename))
end
