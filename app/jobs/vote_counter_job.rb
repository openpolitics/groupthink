# frozen_string_literal: true

class VoteCounterJob < ApplicationJob
  queue_as :default

  def perform(proposal)
    proposal.public_send :count_votes!
  end
end
