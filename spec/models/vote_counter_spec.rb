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
        body: "✅",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: @voter1.login
        )
      ),
      OpenStruct.new(
        body: "✅",
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

  context "casting votes in comments" do
    [
      {
        vote: "yes",
        symbols: [":+1:", ":thumbsup:", "👍", ":white_check_mark:", "✅"],
        score: 1
      },
      {
        vote: "no",
        symbols: [":hand:", "✋", ":negative_squared_cross_mark:", "❎"],
        score: -1
      },
      {
        vote: "block",
        symbols: [":-1:", ":thumbsdown:", "👎", ":no_entry_sign:", "🚫"],
        score: -1000
      },
    ].each do |set|
      set[:symbols].each do |symbol|
        it "should treat #{symbol}  as a #{set[:vote]} vote" do
          pr = create :proposal
          comments = [
            OpenStruct.new(
              body: "here is a vote! #{symbol}",
              created_at: 2.hours.ago,
              user: OpenStruct.new(
                login: @voter1.login
              )
            )      
          ]
          expect(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
          pr.send(:count_votes_in_comments, comments)
          expect(pr.score).to eq set[:score]
        end
      end
    end
  end
  
  it "should ignore votes from proposer" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: "✅",
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
        body: "✅",
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

  it "should actively remove yes votes cast before the last commit" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: "✅",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: @voter1.login
        )
      )
    ]
    # First, calculate the vote count without a recent commit
    expect(pr).to receive(:time_of_last_commit).and_return(3.hours.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.yes.count).to eq 1
    expect(pr.participants.count).to eq 1
    expect(pr.score).to eq 1
    # Now, with the same DB data, let's have a newer commit and check that
    # the score has changed when we recount.
    expect(pr).to receive(:time_of_last_commit).and_return(1.hour.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.yes.count).to eq 0
    expect(pr.participants.count).to eq 1
    expect(pr.score).to eq 0
  end

end
