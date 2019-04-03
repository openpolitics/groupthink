# frozen_string_literal: true

class CreateProposalJob < ApplicationJob
  queue_as :default

  def perform(number)
    Proposal.find_or_create_by(number: number)
  end
end
