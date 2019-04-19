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
      create :proposal, proposer: proposer
      expect(ProposalsMailer).to have_received(:new_proposal).once do |user, proposal|
        expect(user).to eql voter
        expect(proposal).to be_valid
      end
    end

    it "does not go to proposer" do
      create :proposal, proposer: proposer
      expect(ProposalsMailer).to have_received(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql proposer
        expect(proposal).to be_valid
      end
    end

    it "does not go to a voter who has turned off notifications" do
      create :proposal, proposer: proposer
      expect(ProposalsMailer).to have_received(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql no_notifications
        expect(proposal).to be_valid
      end
    end

    it "does not go to people who don't have the vote" do
      create :proposal, proposer: proposer
      expect(ProposalsMailer).to have_received(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql participant
        expect(proposal).to be_valid
      end
    end
  end
end
