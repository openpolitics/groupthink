# frozen_string_literal: true

#
# Count votes on a proposal.
# Triggered when a webhook is received for a new comment on GitHub.
#
class VoteCounterJob < ApplicationJob
  queue_as :default

  def perform(proposal)
    proposal.count_votes!
  end
end
