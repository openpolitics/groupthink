# frozen_string_literal: true

require "rails_helper"

def mock_vote(vote: "✅", created_at: 1.hour.ago, login: "test")
  OpenStruct.new(
    body: "I would like to vote #{vote}, please.",
    created_at: created_at,
    user: OpenStruct.new(
      login: login
    )
  )
end

RSpec.describe VoteCounter do
  let(:voter1) { create :user, contributor: true, notify_new: false }
  let(:voter2) { create :user, contributor: true, notify_new: false }

  let!(:pr) { create :proposal }

  before do
    allow(pr).to receive(:time_of_last_commit).and_return(1.day.ago)
  end

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
    set[:symbols].each do |sym|
      it "counts a '#{sym}' in a comment as a #{set[:vote]} vote" do
        pr.__send__(:count_votes_in_comments, [
          mock_vote(vote: sym, created_at: 2.hours.ago, login: voter1.login)
        ])
        expect(pr.score).to eq set[:score]
        expect(pr.public_send(set[:vote]).count).to eq 1
      end
    end
  end

  it "ignores votes cast by proposer" do
    pr.__send__(:count_votes_in_comments, [
      mock_vote(login: pr.proposer.login)
    ])
    expect(pr.score).to eq 0
  end

  it "counts only the most recent vote cast by each voter" do
    pr.__send__(:count_votes_in_comments, [
      mock_vote(vote: "❎", created_at: 2.hours.ago, login: voter1.login),
      mock_vote(vote: "✅", created_at: 1.hours.ago, login: voter1.login)
    ])
    expect(pr.score).to eq 1
  end

  context "when handling votes from before the last commit" do
    let (:time_before_last_commit) { 2.days.ago }
    let (:login) { voter1.login }

    it "discards yes votes" do
      pr.__send__(:count_votes_in_comments, [
        mock_vote(created_at: time_before_last_commit, login: login)
      ])
      expect(pr.score).to eq 0
    end

    it "preserves no votes" do
      pr.__send__(:count_votes_in_comments, [
        mock_vote(vote: "❎", created_at: time_before_last_commit, login: login)
      ])
      expect(pr.score).to eq(-1)
    end

    it "preserves block votes" do
      pr.__send__(:count_votes_in_comments, [
        mock_vote(vote: "🚫", created_at: time_before_last_commit, login: login)
      ])
      expect(pr.score).to eq(-1000)
    end
  end
end
