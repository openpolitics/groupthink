# frozen_string_literal: true

task :update => :environment do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  User.update_all_from_github!
  Proposal.update_all_from_github!
end
