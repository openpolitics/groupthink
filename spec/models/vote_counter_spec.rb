# frozen_string_literal: true

require "rails_helper"

RSpec.describe VoteCounter do
  let(:voter1) { create :user, contributor: true, notify_new: false }
  let(:voter2) { create :user, contributor: true, notify_new: false }

  it "counts only latest vote per person" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: "✅",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: voter1.login
        )
      ),
      OpenStruct.new(
        body: "✅",
        created_at: 1.hour.ago,
        user: OpenStruct.new(
          login: voter1.login
        )
      )
    ]
    allow(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.score).to eq 1
    expect(pr.yes.first.user).to eq voter1
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
        vote: "abstention",
        symbols: [":zipper_mouth_face:", "🤐"],
        score: 0
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
                login: voter1.login
              )
            )
          ]
          allow(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
          pr.send(:count_votes_in_comments, comments)
          expect(pr.score).to eq set[:score]
          expect(pr.send(set[:vote]).count).to eq 1
        end
      end
    end
  end

  it "ignores votes from proposer" do
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
    allow(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.score).to eq 0
  end

  it "ignores votes before last commit" do
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
    allow(pr).to receive(:time_of_last_commit).and_return(1.hour.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.score).to eq 0
  end

  it "removes yes votes cast before the last commit" do
    pr = create :proposal
    comments = [
      OpenStruct.new(
        body: "✅",
        created_at: 2.hours.ago,
        user: OpenStruct.new(
          login: voter1.login
        )
      )
    ]
    # First, calculate the vote count without a recent commit
    allow(pr).to receive(:time_of_last_commit).and_return(3.hours.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.yes.count).to eq 1
    expect(pr.participants.count).to eq 1
    expect(pr.score).to eq 1
    # Now, with the same DB data, let's have a newer commit and check that
    # the score has changed when we recount.
    allow(pr).to receive(:time_of_last_commit).and_return(1.hour.ago)
    pr.send(:count_votes_in_comments, comments)
    expect(pr.yes.count).to eq 0
    expect(pr.participants.count).to eq 1
    expect(pr.score).to eq 0
  end
end
