require 'rails_helper'

RSpec.describe "webhook POST" do

  it "/ should reject unknown posts" do
    post '/webhook'
    expect(response).to be_bad_request
  end

  it "/ should parse github issue comments correctly" do
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/issue_comment')}, 
      headers: {'X-Github-Event' => "issue_comment"}
    # Check response
    expect(response).to be_ok
    # Should result in PR 32 being updated
    expect(UpdateProposalJob).to have_been_enqueued.with(32)
  end

  it "/ should parse github pull requests correctly" do
    Timecop.freeze
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/pull_request')}, 
      headers: {'X-Github-Event' => "pull_request"}
    # Check response
    expect(response).to be_ok
    # Should result in PR 43 being updated
    expect(CreateProposalJob).to have_been_enqueued.with(43)
    expect(CreateProposalJob).to have_been_enqueued.at(5.seconds.from_now)
    Timecop.return
  end

  it "/ should handle pull request closes correctly" do
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/close_pull_request')}, 
      headers: {'X-Github-Event' => "pull_request"}
    # Check response
    expect(response).to be_ok
    # Should result in PR 43 being closed
    expect(CloseProposalJob).to have_been_enqueued.with(43)
  end

  it "/ should not accept other Github posts" do
    post '/webhook', 
      headers: {'X-Github-Event' => "something_else"}
    expect(response).to be_bad_request
  end

end
