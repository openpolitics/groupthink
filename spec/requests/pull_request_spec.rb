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

  it "should only count latest vote per person" do
    pr = PullRequest.update_from_github!(100)
    pr.abstain.count.should == 1
    pr.abstain[0]['login'].should == 'Floppy'
    pr.agree.count.should == 0
  end

  it "should handle both thumbsup and +1 emoticons as upvotes" do
    pr = PullRequest.update_from_github!(43)
    pr.agree.map{|x| x['login']}.sort.should == ["PaulJRobinson", "philipjohn"]
  end

  it "should ignore votes from proposer" do
    pr = PullRequest.update_from_github!(74)
    pr.agree.count.should == 0
  end

end