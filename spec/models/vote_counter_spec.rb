require 'rails_helper'

RSpec.describe VoteCounter do

  before :each do
    @voter1 = create :user, contributor: true
    @voter2 = create :user, contributor: true
  end

  it "should only count latest vote per person" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: ":-1:",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: @voter1.login
        )
      ),
      OpenStruct.new(
        body: ":+1:",
        created_at: 1.hour.ago,
        user: OpenStruct.new(
          login: @voter1.login
        )
      )
    ]
    expect(pr).to receive(:time_of_last_commit).and_return(1.day.ago).at_least(:once)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.score).to eq 1
    expect(pr.yes.first.user).to eq @voter1
  end

  [":+1:", ":thumbsup:", "👍", ":white_check_mark:", "✅"].each do |symbol|
    it "should treat #{symbol}  as a yes vote" do
      pr = create :proposal
      comments = [
        OpenStruct.new(
          body: "here is a vote! #{symbol}",
          created_at: 2.hours.ago,
          user: OpenStruct.new(
            login: @voter1.login
          )
        )      ]
      expect(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
      pr.send(:count_votes_in_comments, comments)
      expect(pr.score).to eq 1
    end
  end

  it "should ignore votes from proposer" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: ":+1:",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: pr.proposer.login
        )
      )
    ]
    expect(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.score).to eq 0
  end

  it "should ignore votes before last commit" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: ":+1:",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: pr.proposer.login
        )
      )
    ]
    expect(pr).to receive(:time_of_last_commit).and_return(1.hour.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.score).to eq 0
  end

end
