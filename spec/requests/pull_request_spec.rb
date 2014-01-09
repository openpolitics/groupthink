require 'spec_helper'

describe PullRequest do
  
  it "should update pull requests on demand" do
    pr = PullRequest.update_from_github!(43)
    pr.state.should == 'passed'
    redis.get("PullRequest:43").should == "passed"
  end

end