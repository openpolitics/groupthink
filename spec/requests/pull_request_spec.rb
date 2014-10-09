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
    pr.proposer['avatar_url'].should == 'https://avatars.githubusercontent.com/u/3565?v=2'
  end

  it "should only count latest vote per person" do
    pr = PullRequest.update_from_github!(100)
    pr.abstain.count.should == 1
    pr.abstain[0]['login'].should == 'Floppy'
    pr.agree.count.should == 1
    pr.agree[0]['login'].should == 'philipjohn'
  end

  it "should handle both thumbsup and +1 emoticons as upvotes" do
    pr = PullRequest.update_from_github!(43)
    pr.agree.map{|x| x['login']}.sort.should == ["PaulJRobinson", "philipjohn"]
  end

  it "should ignore votes from proposer" do
    pr = PullRequest.update_from_github!(74)
    pr.agree.count.should == 0
  end

  it "should ignore votes before last commit" do
    pr = PullRequest.update_from_github!(135)
    pr.agree.count.should == 0
  end

end
