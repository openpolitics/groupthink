task :update => :environment do  
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  User.update_all_from_github!
  Proposal.recreate_all_from_github!
end