task :merge => :environment do  
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Proposal.each do |p|
    case p.merge_if_passed!
    when true
      logger.error "##{p.number} was merged"
    when false
      logger.error "##{p.number} couldn't be merged - may have conflicts, CLA, or update"
    else
      # Nothing happened
    end
  end
end