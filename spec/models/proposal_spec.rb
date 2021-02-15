# frozen_string_literal: true

require "rails_helper"

RSpec.describe Proposal, type: :model do
  context "when checking overall state without a CLA" do
    let(:pr) { create :proposal }

    context "when the upstream PR has been closed" do
      before do
        allow(pr).to receive(:pr_closed?).and_return(true)
      end

      it "merged PRs are marked as accepted" do
        allow(pr).to receive(:pr_merged?).and_return(true)
        pr.update_state!
        expect(pr.state).to eq "accepted"
      end

      it "unmerged PRs are marked as rejected", :vcr do
        allow(pr).to receive(:pr_merged?).and_return(false)
        pr.update_state!
        expect(pr.state).to eq "rejected"
      end
    end

    context "when the upstream PR is still open" do
      around do |example|
        env = {
          YES_WEIGHT: "1",
          NO_WEIGHT: "-1",
          BLOCK_WEIGHT: "-1000",
          PASS_THRESHOLD: "2",
          BLOCK_THRESHOLD: "-1",
          MIN_AGE: "7",
          MAX_AGE: "90",
          CLA_URL: nil,
        }
        ClimateControl.modify env do
          example.run
        end
      end

      before do
        allow(pr).to receive(:pr_closed?).and_return(false)
      end

      it "stores old pull requests as dead" do
        allow(pr).to receive_messages(age: 100)
        pr.update_state!
        expect(pr.state).to eq "dead"
      end

      it "stores blocked pull requests as blocked" do
        allow(pr).to receive_messages(score: -500, age: 10)
        pr.update_state!
        expect(pr.state).to eq "blocked"
      end

      it "stores PRs with enough votes and enough time as passed" do
        allow(pr).to receive_messages(score: 5, age: 10)
        pr.update_state!
        expect(pr.state).to eq "passed"
      end

      it "stores PRs with enough votes and not enough time as agreed" do
        allow(pr).to receive_messages(score: 5, age: 5)
        pr.update_state!
        expect(pr.state).to eq "agreed"
      end

      it "stores PRs with not enough votes and not enough time as pending" do
        allow(pr).to receive_messages(score: 1, age: 5)
        pr.update_state!
        expect(pr.state).to eq "waiting"
      end
    end
  end

  context "when checking overall state with a signed CLA" do
    let(:proposer) { create :user, cla_accepted: true }
    let(:pr) { create :proposal, proposer: proposer }

    context "when the upstream PR is still open" do
      around do |example|
        env = {
          YES_WEIGHT: "1",
          NO_WEIGHT: "-1",
          BLOCK_WEIGHT: "-1000",
          PASS_THRESHOLD: "2",
          BLOCK_THRESHOLD: "-1",
          MIN_AGE: "7",
          MAX_AGE: "90",
          CLA_URL: "https://example.org/cla.html",
        }
        ClimateControl.modify env do
          example.run
        end
      end

      before do
        allow(pr).to receive(:pr_closed?).and_return(false)
      end

      it "stores old pull requests as dead" do
        allow(pr).to receive_messages(age: 100)
        pr.update_state!
        expect(pr.state).to eq "dead"
      end

      it "stores blocked pull requests as blocked" do
        allow(pr).to receive_messages(score: -500, age: 10)
        pr.update_state!
        expect(pr.state).to eq "blocked"
      end

      it "stores PRs with enough votes and enough time as passed" do
        allow(pr).to receive_messages(score: 5, age: 10)
        pr.update_state!
        expect(pr.state).to eq "passed"
      end

      it "stores PRs with enough votes and not enough time as agreed" do
        allow(pr).to receive_messages(score: 5, age: 5)
        pr.update_state!
        expect(pr.state).to eq "agreed"
      end

      it "stores PRs with not enough votes and not enough time as pending" do
        allow(pr).to receive_messages(score: 1, age: 5)
        pr.update_state!
        expect(pr.state).to eq "waiting"
      end
    end
  end

  context "when checking overall state with an unsigned CLA" do
    let(:proposer) { create :user, cla_accepted: false }
    let(:pr) { create :proposal, proposer: proposer }

    context "when the upstream PR is still open" do
      around do |example|
        env = {
          YES_WEIGHT: "1",
          NO_WEIGHT: "-1",
          BLOCK_WEIGHT: "-1000",
          PASS_THRESHOLD: "2",
          BLOCK_THRESHOLD: "-1",
          MIN_AGE: "7",
          MAX_AGE: "90",
          CLA_URL: "https://example.org/cla.html",
        }
        ClimateControl.modify env do
          example.run
        end
      end

      before do
        allow(pr).to receive(:pr_closed?).and_return(false)
      end

      it "stores old pull requests as dead" do
        allow(pr).to receive_messages(age: 100)
        pr.update_state!
        expect(pr.state).to eq "dead"
      end

      it "stores blocked pull requests as blocked" do
        allow(pr).to receive_messages(score: -500, age: 10)
        pr.update_state!
        expect(pr.state).to eq "blocked"
      end

      it "stores PRs with enough votes and enough time as passed" do
        allow(pr).to receive_messages(score: 5, age: 10)
        pr.update_state!
        expect(pr.state).to eq "blocked"
      end

      it "stores PRs with enough votes and not enough time as agreed" do
        allow(pr).to receive_messages(score: 5, age: 5)
        pr.update_state!
        expect(pr.state).to eq "blocked"
      end

      it "stores PRs with not enough votes and not enough time as pending" do
        allow(pr).to receive_messages(score: 1, age: 5)
        pr.update_state!
        expect(pr.state).to eq "blocked"
      end
    end
  end

  context "with notification of new proposals" do
    let!(:proposer) { create :user, voter: true, notify_new: true }
    let!(:voter) { create :user, voter: true, notify_new: true }
    let!(:no_notifications) { create :user, voter: true, notify_new: false }
    let!(:participant) { create :user, voter: false, notify_new: true }
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
