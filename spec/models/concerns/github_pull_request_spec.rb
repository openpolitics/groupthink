# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubPullRequest, type: :model do
  let!(:pr) { create :proposal }

  around do |example|
    env = {
      GITHUB_REPO: "example/repo",
      MAX_AGE: "90",
      MIN_AGE: "7",
      PASS_THRESHOLD: "2",
    }
    ClimateControl.modify env do
      example.run
    end
  end

  it "adds a helpful comment for PRs that are closed without merging" do
    allow(Octokit).to receive(:add_comment).and_return(nil)
    allow(Octokit).to receive(:close_pull_request).and_return(nil)
    pr.__send__(:close_pr!)
    expect(Octokit).to have_received(:add_comment).with("example/repo", pr.number,
      /Closed automatically: maximum age exceeded. Please feel free to resubmit this/)
  end

  context "when setting vote build status" do
    before do
      allow(pr).to receive(:set_build_status)
      allow(pr).to receive(:score).and_return(1)
    end

    it "sets blocked status" do
      allow(pr).to receive(:blocked?).and_return(true)
      pr.__send__(:set_vote_build_status)
      expect(pr).to have_received(:set_build_status).with(:failure,
        "The proposal is blocked.", "groupthink/votes")
    end

    it "sets passed status" do
      allow(pr).to receive(:blocked?).and_return(false)
      allow(pr).to receive(:passed?).and_return(true)
      pr.__send__(:set_vote_build_status)
      expect(pr).to have_received(:set_build_status).with(:success,
        "The proposal has been agreed.", "groupthink/votes")
    end

    it "sets pending status" do
      allow(pr).to receive(:blocked?).and_return(false)
      allow(pr).to receive(:passed?).and_return(false)
      pr.__send__(:set_vote_build_status)
      expect(pr).to have_received(:set_build_status).with(:pending,
        "The proposal is waiting for more votes; 1 more needed.", "groupthink/votes")
    end
  end

  context "when setting time build status" do
    before do
      allow(pr).to receive(:set_build_status)
    end

    it "sets dead status" do
      allow(pr).to receive(:age).and_return(300)
      pr.__send__(:set_time_build_status)
      expect(pr).to have_received(:set_build_status).with(:failure,
        "The change has been open for more than 90 days, and should be closed (age: 300d).",
        "groupthink/time")
    end

    it "sets successful status" do
      allow(pr).to receive(:age).and_return(10)
      pr.__send__(:set_time_build_status)
      expect(pr).to have_received(:set_build_status).with(:success,
        "The change has been open long enough to be merged (age: 10d).",
        "groupthink/time")
    end

    it "sets waiting status" do
      allow(pr).to receive(:age).and_return(3)
      pr.__send__(:set_time_build_status)
      expect(pr).to have_received(:set_build_status).with(:pending,
        "The change has not yet been open for 7 days (age: 3d).",
        "groupthink/time")
    end
  end
end
