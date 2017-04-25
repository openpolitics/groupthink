class CloseProposalJob < ApplicationJob
  queue_as :default

  def perform(number)
    Proposal.find_by(number: number).try(:close!)
  end
end
