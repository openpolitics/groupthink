# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalsController, type: :controller do
  render_views

  let(:proposer) { create :user }
  let!(:proposal) { create :proposal, proposer: proposer }

  around do |example|
    env = {
      YES_WEIGHT: "1",
      NO_WEIGHT: "-1",
      BLOCK_WEIGHT: "-1000",
      PASS_THRESHOLD: "2",
      BLOCK_THRESHOLD: "-1",
      MIN_AGE: "7",
      MAX_AGE: "90",
      PROJECT_NAME: "Test Project",
      PROJECT_URL: "http://project.example.com",
      SITE_URL: "http://groupthink.example.com",
      GITHUB_REPO: "example/repo"
    }
    ClimateControl.modify env do
      example.run
    end
  end

  it "shows index page" do
    get :index
    expect(response).to be_ok
  end

  it "includes project URL in index page" do
    get :index
    expect(response.body).to include "http://project.example.com"
  end

  context "when showing proposal page" do
    before do
      allow(Octokit).to receive(:pull_request_commits).and_return([])
      allow(Octokit).to receive(:pull_request).and_return(
        OpenStruct.new(
          body: "Lorem Ipsum Proposal Title",
          created_at: 1.hour.ago,
        )
      )
      allow(Octokit).to receive(:issue_comments).and_return([])
      get :show, params: { id: proposal.number }
    end

    it "includes details of the proposer" do
      expect(response.body).to include proposer.login
    end

    it "includes the proposal title" do
      expect(response.body).to include "Lorem Ipsum Proposal Title"
    end
  end

  context "when adding comments" do
    let(:client) { instance_double(Octokit::Client) }

    before do
      allow(Octokit::Client).to receive(:new).and_return(client)
      allow(client).to receive(:add_comment)
    end

    context "when not logged in" do
      it "redirects to login" do
        put :comment, params: { id: proposal.number }
        expect(response.redirect_url).to eq "http://test.host/sign_in"
      end

      it "does not add comment" do
        put :comment, params: { id: proposal.number }
        expect(client).not_to have_received(:add_comment)
      end
    end

    context "when logged in" do
      before do
        sign_in proposer
      end

      it "posts comment" do
        put :comment, params: { id: proposal.number, comment: "hello" }
        expect(client).to have_received(:add_comment).once
      end

      it "redirects back to proposal page after posting" do
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

    it "/ should respond to pings with a 200" do
      # Set POST
      request.headers["X-Github-Event"] = "ping"
      post :webhook
      expect(response).to be_ok
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
