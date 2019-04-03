task :merge => :environment do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Proposal.where(state: "passed").each do |p|
    case p.merge_if_passed!
    when true
      Rails.logger.error "##{p.number} was merged"
      sleep(10)
    when false
      Rails.logger.error "##{p.number} couldn't be merged - may have conflicts, CLA, or update"
    else
      # Nothing happened
    end
  end
end
