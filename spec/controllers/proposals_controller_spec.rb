# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalsController, type: :controller do
  render_views

  let(:proposer) { create :user, contributor: true, notify_new: true }
  let(:proposal) { create :proposal, proposer: proposer }

  it "shows index page" do
    get :index
    expect(response).to be_ok
  end

  it "includes site URL in index page" do
    get :index
    expect(response.body).to include "https://openpolitics.org.uk"
  end

  it "shows individual proposal page" do
    # Stub out the calls to github data
    allow_any_instance_of(GithubPullRequest).to receive(:github_commits).and_return([])
    allow_any_instance_of(Proposal).to receive(:description).and_return("test")
    allow_any_instance_of(Proposal).to receive(:submitted_at).and_return(1.hour.ago)
    allow_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return([])
    # Test show page
    get :show, params: { id: proposal.number }
    expect(response.body).to include proposer.login
  end

  context "when adding comments" do
    context "when not logged in" do
      it "redirects to login" do
        put :comment, params: { id: proposal.number }
        expect(response.redirect_url).to eq "http://test.host/sign_in"
      end

      it "does not add comment" do
        expect_any_instance_of(Octokit::Client).not_to receive(:add_comment)
        put :comment, params: { id: proposal.number }
      end
    end

    context "when logged in" do
      it "posts comment" do
        expect_any_instance_of(Octokit::Client).to receive(:add_comment).once
        sign_in proposer
        put :comment, params: { id: proposal.number, comment: "hello" }
      end

      it "redirects back to proposal page after posting" do
        allow_any_instance_of(Octokit::Client).to receive(:add_comment).once
        sign_in proposer
        put :comment, params: { id: proposal.number, comment: "hello" }
        expect(response.redirect_url).to eq "http://test.host/proposals/#{proposal.number}"
      end
    end
  end

  describe "webhook" do
    it "/ should reject unknown posts" do
      post :webhook
      expect(response).to be_bad_request
    end

    it "/ should enqueue github issue comments correctly" do
      # Set POST
      request.headers["X-Github-Event"] = "issue_comment"
      post :webhook,
        params: { payload: load_fixture("requests/issue_comment") }
      # Should result in PR 32 being updated
      expect(UpdateProposalJob).to have_been_enqueued.with(32)
    end

    it "/ should enqueue github pull requests correctly" do
      # Set POST
      request.headers["X-Github-Event"] = "pull_request"
      post :webhook,
        params: { payload: load_fixture("requests/pull_request") }
      # Should result in PR 43 being created
      expect(CreateProposalJob).to have_been_enqueued.with(43)
    end

    it "/ should enqueue pull request closes correctly" do
      # Set POST
      request.headers["X-Github-Event"] = "pull_request"
      post :webhook,
        params: { payload: load_fixture("requests/close_pull_request") }
      # Should result in PR 43 being closed
      expect(CloseProposalJob).to have_been_enqueued.with(43)
    end

    it "/ should not accept other Github posts" do
      request.headers["X-Github-Event"] = "something_else"
      post :webhook
      expect(response).to be_bad_request
    end
  end
end
