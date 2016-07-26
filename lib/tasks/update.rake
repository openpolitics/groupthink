task :update => :environment do
  User.update_all_from_github!
  Proposal.recreate_all_from_github!
end