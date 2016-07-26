require "sinatra/activerecord/rake"

namespace :db do
  task :load_config do
    require "./votebot"
  end
end

task :update do
  require_relative 'votebot'
  User.update_all_from_github!
  PullRequest.recreate_all_from_github!
end

unless ENV['RACK_ENV'] == 'production'
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
end