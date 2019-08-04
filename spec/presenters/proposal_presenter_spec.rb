# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalPresenter, type: :presenter do
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
      let(:item) { described_class.new(pr).activity_log[0] }
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
      let(:item) { described_class.new(pr).activity_log[0] }
      let!(:submission_time) { 1.hour.ago }

      before do
        user = create :user, login: "noobmaster69" # 💜 Korg
        allow(pr).to receive(:github_commits).and_return([])
        allow(pr).to receive(:github_comments).and_return([
          OpenStruct.new(
            body: "This is a comment",
            user: OpenStruct.new(
              login: user.login,
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
        expect(described_class.new(pr).activity_log).to be_empty
      end
    end

    context "with commits" do
      let(:item) { described_class.new(pr).activity_log[0] }
      let!(:submission_time) { 1.hour.ago }

      before do
        user = create :user, login: "noobmaster69" # 💜 Korg
        allow(pr).to receive(:github_commits).and_return([
          OpenStruct.new(
            sha: "123456",
            commit: {
              author: {
                name: user.login,
                date: submission_time,
              }
            },
          )
        ])
        allow(pr).to receive(:github_comments).and_return([])
        allow(pr).to receive(:description).and_return(nil)
      end

      it "marks commits as a diff type" do
        expect(item[0]).to eq("diff")
      end

      it "includes the commit SHA" do
        expect(item[1][:sha]).to eq("123456")
      end

      it "includes the submitted date" do
        expect(item[1][:time]).to eq(submission_time)
      end

      it "includes details of the user who made the comment" do
        expect(item[1][:user].login).to eq("noobmaster69")
      end
    end
  end
end
