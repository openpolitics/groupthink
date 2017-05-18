task :merge => :environment do  
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Proposal.each do |p|
    p.merge_if_passed!
  end
end