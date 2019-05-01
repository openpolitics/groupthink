# frozen_string_literal: true

#
# Update a proposal in the database with data from GitHub.
# Triggered when a webhook is received for an updated PR on GitHub.
#
class UpdateProposalJob < ApplicationJob
  queue_as :default

  def perform(number)
    Proposal.find_by(number: number).try(:update_from_github!)
  end
end
