# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalsController, type: :controller do
  render_views

  before :each do
    @proposer = create :user, contributor: true, notify_new: true
    @proposal = create :proposal, proposer: @proposer
  end

  it "should show index page" do
    get :index
    expect(response).to be_ok
    expect(response.body).to include "https://openpolitics.org.uk"
  end

  it "should show individual proposal page" do
    # Stub out the calls to github data
    allow_any_instance_of(GithubPullRequest).to receive(:github_commits).and_return([])
    allow_any_instance_of(Proposal).to receive(:description).and_return("test")
    allow_any_instance_of(Proposal).to receive(:submitted_at).and_return(1.hour.ago)
    allow_any_instance_of(Octokit::Client).to receive(:issue_comments).and_return([])
    # Test show page
    get :show, params: { id: @proposal.number }
    expect(response).to be_ok
    expect(response.body).to include @proposer.login
  end

  context "adding comments" do
    it "should redirect to login if not logged in" do
      expect_any_instance_of(Octokit::Client).to receive(:add_comment).never
      put :comment, params: { id: @proposal.number }
      expect(response).to be_redirect
      expect(response.redirect_url).to eq "http://test.host/sign_in"
    end

    it "should post comment if logged in" do
      expect_any_instance_of(Octokit::Client).to receive(:add_comment).once
      sign_in @proposer
      put :comment, params: { id: @proposal.number, comment: "hello" }
      expect(response).to be_redirect
      expect(response.redirect_url).to eq "http://test.host/proposals/#{@proposal.number}"
    end
  end
end
