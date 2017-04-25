class UpdateProposalJob < ApplicationJob
  queue_as :default

  def perform(number)
    Proposal.find_by(number: number).try(:update_from_github!)
  end
end
