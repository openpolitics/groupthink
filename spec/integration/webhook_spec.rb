require 'rails_helper'

RSpec.describe "webhook POST" do

  it "/ should reject unknown posts" do
    post '/webhook'
    expect(response).to be_bad_request
  end

  it "/ should parse github issue comments correctly" do
    # Should result in PR 32 being updated
    double = instance_double("proposal", number: 32)
    expect(Proposal).to receive(:find_or_create_by).with(number: 32).and_return(double)
    expect(double).to receive(:update_from_github!)
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/issue_comment')}, 
      headers: {'X-Github-Event' => "issue_comment"}
    # Check response
    expect(response).to be_ok
  end

  it "/ should parse github pull requests correctly" do
    # Should result in PR 43 being updated
    expect(Proposal).to receive(:find_or_create_by).with(number: 43).once
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/pull_request')}, 
      headers: {'X-Github-Event' => "pull_request"}
    # Check response
    expect(response).to be_ok
  end

  it "/ should handle pull request closes correctly" do
    # Should result in PR 43 being closed
    double = instance_double("proposal", number: 43)
    expect(Proposal).to receive(:find_or_create_by).with(number: 43).and_return(double)
    expect(double).to receive(:close!)
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/close_pull_request')}, 
      headers: {'X-Github-Event' => "pull_request"}
    # Check response
    expect(response).to be_ok
  end

  it "/ should not accept other Github posts" do
    post '/webhook', 
      headers: {'X-Github-Event' => "something_else"}
    expect(response).to be_bad_request
  end

end
