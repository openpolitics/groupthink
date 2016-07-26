describe "webhook POST", :vcr do

  it "/ should reject unknown posts" do
    post '/webhook'
    expect(last_response).to be_bad_request
  end

  it "/ should parse github issue comments correctly" do
    # Should result in PR 32 being updated
    expect(Proposal).to receive(:create_from_github!).with(32).once
    # Set POST
    header 'X-Github-Event', "issue_comment"
    post '/webhook', payload: load_fixture('requests/issue_comment')
    # Check response
    expect(last_response).to be_ok
  end

  it "/ should parse github pull requests correctly" do
    # Should result in PR 43 being updated
    expect(Proposal).to receive(:create_from_github!).with(43).once
    # Set POST
    header 'X-Github-Event', "pull_request"
    post '/webhook', payload: load_fixture('requests/pull_request')
    # Check response
    expect(last_response).to be_ok
  end

  it "/ should handle pull request closes correctly" do
    # Set POST
    header 'X-Github-Event', "pull_request"
    post '/webhook', payload: load_fixture('requests/close_pull_request')
    # Check response
    expect(last_response).to be_ok
  end

  it "/ should not accept other Github posts" do
    header 'X-Github-Event', "something_else"
    post '/webhook'
    expect(last_response).to be_bad_request
  end

end
