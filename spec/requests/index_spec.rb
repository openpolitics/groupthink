require 'spec_helper'
require 'json'

describe "index page" do
  
  it "should allow accessing the home page" do
    get '/'
    last_response.should be_ok
    last_response.body.should include "http://openpolitics.org.uk"
  end
  
  it "/ should reject unknown posts" do
    post '/'
    last_response.should be_bad_request
  end
  
  it "/ should parse github issue comments correctly" do
    # Should result in PR 32 being updated
    Votebot.any_instance.should_receive(:update_pr).with(32).once
    # Set POST
    header 'X-Github-Event', "issue_comment"
    post '/', payload: load_fixture('requests/issue_comment')
    # Check response
    last_response.should be_ok
  end

  it "/ should parse github pull requests correctly" do
    # Should result in PR 43 being updated
    Votebot.any_instance.should_receive(:update_pr).with(43).once
    # Set POST
    header 'X-Github-Event', "pull_request"
    post '/', payload: load_fixture('requests/pull_request')
    # Check response
    last_response.should be_ok
  end

  it "/ should not accept other Github posts" do
    header 'X-Github-Event', "something_else"
    post '/'
    last_response.should be_bad_request
  end

end