require 'spec_helper'

describe PullRequest, :vcr do

  it "should update pull requests on demand" do
    Timecop.freeze(2014,1,20)
    pr = PullRequest.update_from_github!(43)
    pr.state.should == 'passed'
    redis.get("PullRequest:43").should include("passed")
    Timecop.return
  end

  it "should include proposer information" do
    pr = PullRequest.update_from_github!(43)
    pr.proposer['login'].should == 'Floppy'
    pr.proposer['avatar_url'].should =~ /https:\/\/avatars.githubusercontent.com\/u\/3565/
  end

  it "should only count latest vote per person" do
    pr = PullRequest.update_from_github!(100)
    pr.agree.count.should == 2
    pr.agree.map{|x| x['login']}.sort.should == ["Floppy", "philipjohn"]
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
