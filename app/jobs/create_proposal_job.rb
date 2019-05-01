# frozen_string_literal: true

#
# Create a proposal in the database.
# Triggered when a webhook is received for a new PR on GitHub.
#
class CreateProposalJob < ApplicationJob
  queue_as :default

  def perform(number)
    Proposal.find_or_create_by(number: number)
  end
end
