# frozen_string_literal: true

task merge: :environment do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
  Proposal.where(state: "passed").each do |p|
    if p.merge_pr!
      Rails.logger.error "##{p.number} was merged"
      sleep(10)
    else
      Rails.logger.error "##{p.number} couldn't be merged - may have conflicts, CLA, or update"
    end
  end
end
