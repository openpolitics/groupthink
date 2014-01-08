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
  
  it "/ should accept Github issue comment posts" do
    header 'X-Github-Event', "issue_comment"
    post '/'
    last_response.should be_ok
  end

  it "/ should accept Github pull request posts" do
    header 'X-Github-Event', "pull_request"
    post '/'
    last_response.should be_ok
  end

  it "/ should not accept other Github posts" do
    header 'X-Github-Event', "something_else"
    post '/'
    last_response.should be_bad_request
  end

end