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
    header 'X-Github-Event', "issue_comment"
    post '/', payload: load_fixture('requests/issue_comment')
    last_response.should be_ok
  end

  it "/ should parse github pull requests correctly" do
    header 'X-Github-Event', "pull_request"
    post '/', payload: load_fixture('requests/pull_request')
    last_response.should be_ok
  end

  it "/ should not accept other Github posts" do
    header 'X-Github-Event', "something_else"
    post '/'
    last_response.should be_bad_request
  end

end