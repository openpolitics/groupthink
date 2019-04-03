# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/proposals
class ProposalsPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/proposals/new_proposal
  def new_proposal
    ProposalsMailer.new_proposal(User.first, Proposal.first)
  end
end
