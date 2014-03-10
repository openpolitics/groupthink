require 'spec_helper'

describe PullRequest, :vcr do
  
  it "should update pull requests on demand" do
    pr = PullRequest.update_from_github!(43)
    pr.state.should == 'passed'
    redis.get("PullRequest:43").should include("passed")
  end

  it "should include proposer information" do
    pr = PullRequest.update_from_github!(43)
    pr.proposer['login'].should == 'Floppy'
    pr.proposer['avatar_url'].should == 'https://gravatar.com/avatar/c150a49c7709fa40bffca545ecf8942d?d=https%3A%2F%2Fidenticons.github.com%2Fe6e713296627dff6475085cc6a224464.png&r=x'
  end

end