# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubPullRequest, type: :model do
  let!(:pr) { create :proposal }

  around do |example|
    env = {
      GITHUB_REPO: "example/repo"
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
end
