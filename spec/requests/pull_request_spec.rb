describe PullRequest, :vcr do

  it "should update pull requests on demand" do
    Timecop.freeze(2015,5,30)
    pr = PullRequest.create_from_github!(356)
    expect(pr.state).to eq 'passed'
    Timecop.return
  end

  it "should include proposer information" do
    pr = PullRequest.create_from_github!(43)
    expect(pr.proposer.login).to eq 'Floppy'
  end

  it "should only count latest vote per person" do
    pr = PullRequest.create_from_github!(100)
    expect(pr.agree.count).to eq 2
    expect(pr.agree.map{|x| x.user.login}.sort).to eq ["Floppy", "philipjohn"]
  end

  it "should handle both thumbsup and +1 emoticons as upvotes" do
    pr = PullRequest.create_from_github!(356)
    expect(pr.agree.map{|x| x.user.login}.sort).to eq ["Floppy", "philipjohn"]
  end

  it "should ignore votes from proposer" do
    pr = PullRequest.create_from_github!(74)
    expect(pr.agree.count).to eq 0
  end

  it "should ignore votes before last commit" do
    pr = PullRequest.create_from_github!(135)
    expect(pr.agree.count).to eq 1
  end

end
