RSpec.describe "webhook POST", :vcr do

  it "/ should reject unknown posts" do
    post '/webhook'
    expect(response).to be_bad_request
  end

  it "/ should parse github issue comments correctly" do
    # Should result in PR 32 being updated
    expect(Proposal).to receive(:create_from_github!).with(32).once
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/issue_comment')}, 
      headers: {'X-Github-Event' => "issue_comment"}
    # Check response
    expect(response).to be_ok
  end

  it "/ should parse github pull requests correctly" do
    # Should result in PR 43 being updated
    expect(Proposal).to receive(:create_from_github!).with(43).once
    # Set POST
    post '/webhook', 
      params: {payload: load_fixture('requests/pull_request')}, 
      headers: {'X-Github-Event' => "pull_request"}
    # Check response
    expect(response).to be_ok
  end

  it "/ should handle pull request closes correctly" do
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
