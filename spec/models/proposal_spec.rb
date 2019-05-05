# frozen_string_literal: true

require "rails_helper"

RSpec.describe Proposal, type: :model do
  context "when checking overall state" do
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

  context "when generating merged activity log" do
    let(:pr) { create :proposal }

    around do |example|
      env = {
        GITHUB_REPO: "example/repo",
      }
      ClimateControl.modify env do
        example.run
      end
    end

    context "with a description" do
      let(:item) { pr.activity_log[0] }
      let!(:submission_time) { 1.day.ago }

      before do
        allow(pr).to receive(:github_commits).and_return([])
        allow(pr).to receive(:github_comments).and_return([])
        allow(pr).to receive(:description).and_return("Lorem ipsum this is a description")
        allow(pr).to receive(:submitted_at).and_return(submission_time)
      end

      it "marks the description as a comment type" do
        expect(item[0]).to eq("comment")
      end

      it "includes the description in the body" do
        expect(item[1][:body]).to eq("Lorem ipsum this is a description")
      end

      it "includes the submitted date" do
        expect(item[1][:time]).to eq(submission_time)
      end
    end

    context "with a comment" do
      let(:item) { pr.activity_log[0] }
      let!(:submission_time) { 1.hour.ago }

      before do
        create :user, login: "noobmaster69" # 💜 Korg
        allow(pr).to receive(:github_commits).and_return([])
        allow(pr).to receive(:github_comments).and_return([
          OpenStruct.new(
            body: "This is a comment",
            user: OpenStruct.new(
              login: "noobmaster69",
            ),
            created_at: submission_time,
          )
        ])
        allow(pr).to receive(:description).and_return(nil)
      end

      it "marks comments as a comment type" do
        expect(item[0]).to eq("comment")
      end

      it "includes the comment text in the body" do
        expect(item[1][:body]).to eq("This is a comment")
      end

      it "includes the submitted date" do
        expect(item[1][:time]).to eq(submission_time)
      end

      it "includes details of the user who made the comment" do
        expect(item[1][:user].login).to eq("noobmaster69")
      end
    end

    context "with only an instruction comment" do
      before do
        allow(pr).to receive(:github_commits).and_return([])
        allow(pr).to receive(:github_comments).and_return([
          instance_double("comment",
            body: "<!-- votebot instructions --> this comment should be ignored",
          )
        ])
        allow(pr).to receive(:description).and_return(nil)
      end

      it "has an empty activity log" do
        expect(pr.activity_log).to be_empty
      end
    end

  end
end
