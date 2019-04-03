task :close => :environment do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Proposal.where(state: "dead").each do |p|
    p.close_if_dead!
    Rails.logger.info "##{p.number} was closed"
  end
end
