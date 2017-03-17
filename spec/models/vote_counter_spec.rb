require 'rails_helper'

RSpec.describe VoteCounter do

  it "should only count latest vote per person", :vcr do
    pr = Proposal.create(number: 100)
    expect(pr.yes.count).to eq 2
    expect(pr.yes.map{|x| x.user.login}.sort).to eq ["Floppy", "philipjohn"]
  end

  it "should handle both thumbsup and +1 emoticons as yes votes", :vcr do
    pr = Proposal.create(number: 356)
    expect(pr.yes.map{|x| x.user.login}.sort).to eq ["Floppy", "philipjohn"]
  end

  it "should handle emoji yes votes", :vcr do
    pr = Proposal.create(number: 433)
    expect(pr.yes.map{|x| x.user.login}.sort).to eq ["Floppy"]
  end

  it "should ignore votes from proposer", :vcr do
    pr = Proposal.create(number: 74)
    expect(pr.yes.count).to eq 0
  end

  it "should ignore votes before last commit", :vcr do
    pr = Proposal.create(number: 135)
    expect(pr.yes.count).to eq 1
  end

  it "should store merged pull requests as accepted", :vcr do
    pr = Proposal.create(number: 43)
    expect(pr.state).to eq 'accepted'
  end

  it "should store closed and unmerged pull requests as rejected", :vcr do
    pr = Proposal.create(number: 9)
    expect(pr.state).to eq 'rejected'
  end

end
