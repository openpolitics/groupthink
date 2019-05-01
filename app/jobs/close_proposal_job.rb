# frozen_string_literal: true

#
# Closes a proposal.
# Triggered when a PR is closed on GitHub.
#
class CloseProposalJob < ApplicationJob
  queue_as :default

  def perform(number)
    Proposal.find_by(number: number).try(:close!)
  end
end
