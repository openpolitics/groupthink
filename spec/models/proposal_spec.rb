require 'rails_helper'

RSpec.describe Proposal, :vcr do

  it "should update proposals on demand" do
    Timecop.freeze(2015,5,30)
    pr = Proposal.create(number: 356)
    expect(pr.state).to eq 'accepted'
    Timecop.return
  end

  it "should include proposer information" do
    pr = Proposal.create(number: 43)
    expect(pr.proposer.login).to eq 'Floppy'
  end

  it "should only count latest vote per person" do
    pr = Proposal.create(number: 100)
    expect(pr.agree.count).to eq 2
    expect(pr.agree.map{|x| x.user.login}.sort).to eq ["Floppy", "philipjohn"]
  end

  it "should handle both thumbsup and +1 emoticons as upvotes" do
    pr = Proposal.create(number: 356)
    expect(pr.agree.map{|x| x.user.login}.sort).to eq ["Floppy", "philipjohn"]
  end

  it "should handle emoji upvotes" do
    pr = Proposal.create(number: 433)
    expect(pr.agree.map{|x| x.user.login}.sort).to eq ["Floppy"]
  end

  it "should ignore votes from proposer" do
    pr = Proposal.create(number: 74)
    expect(pr.agree.count).to eq 0
  end

  it "should ignore votes before last commit" do
    pr = Proposal.create(number: 135)
    expect(pr.agree.count).to eq 1
  end

  it "should store merged pull requests as accepted" do
    pr = Proposal.create(number: 43)
    expect(pr.state).to eq 'accepted'
  end

  it "should store closed and unmerged pull requests as rejected" do
    pr = Proposal.create(number: 9)
    expect(pr.state).to eq 'rejected'
  end

end
