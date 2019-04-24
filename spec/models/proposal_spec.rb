# frozen_string_literal: true

require "rails_helper"

RSpec.describe Proposal do
  context "when checking overall state" do
    it "stores merged pull requests as accepted" do
      # stub state indicators
      allow_any_instance_of(described_class).to receive(:pr_closed?).and_return(true)
      allow_any_instance_of(described_class).to receive(:pr_merged?).and_return(true)
      # Test
      pr = create :proposal
      pr.update_state!
      expect(pr.state).to eq "accepted"
    end

    it "stores closed and unmerged pull requests as rejected", :vcr do
      # stub state indicators
      allow_any_instance_of(described_class).to receive(:pr_closed?).and_return(true)
      allow_any_instance_of(described_class).to receive(:pr_merged?).and_return(false)
      # Test
      pr = create :proposal
      pr.update_state!
      expect(pr.state).to eq "rejected"
    end
  end

  context "with notification of new proposals" do
    let!(:proposer) { create :user, contributor: true, notify_new: true }
    let!(:voter) { create :user, contributor: true, notify_new: true }
    let!(:no_notifications) { create :user, contributor: true, notify_new: false }
    let!(:participant) { create :user, contributor: false, notify_new: true }
    let!(:mail) { instance_double("mail") }

    before do
      allow(mail).to receive(:deliver_later)
      allow(ProposalsMailer).to receive(:new_proposal).and_return(mail)
    end

    it "goes to voters" do
      proposal = create :proposal, proposer: proposer
      expect(ProposalsMailer).to have_received(:new_proposal).with(voter, proposal)
    end

    it "does not go to proposer" do
      proposal = create :proposal, proposer: proposer
      expect(ProposalsMailer).not_to have_received(:new_proposal).with(proposer, proposal)
    end

    it "does not go to a voter who has turned off notifications" do
      proposal = create :proposal, proposer: proposer
      expect(ProposalsMailer).not_to have_received(:new_proposal).with(no_notifications, proposal)
    end

    it "does not go to people who don't have the vote" do
      proposal = create :proposal, proposer: proposer
      expect(ProposalsMailer).not_to have_received(:new_proposal).with(participant, proposal)
    end
  end
end
