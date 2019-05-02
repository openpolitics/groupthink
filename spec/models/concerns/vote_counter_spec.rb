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

RSpec.describe VoteCounter, type: :model do
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
      context "when casting a vote with '#{sym}'" do
        before do
          pr.__send__(:count_votes_in_comments, [
            mock_vote(vote: sym, created_at: 2.hours.ago, login: voter1.login)
          ])
        end

        it "counts as a #{set[:vote]} vote" do
          expect(pr.public_send(set[:vote]).count).to eq 1
        end

        it "calculates correct score for a #{set[:vote]} vote" do
          expect(pr.score).to eq set[:score]
        end
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

  context "when setting vote build status" do
    before do
      allow(pr).to receive(:set_build_status)
      allow(pr).to receive(:score).and_return(1)
    end

    it "sets blocked status" do
      allow(pr).to receive(:blocked?).and_return(true)
      pr.__send__(:set_vote_build_status)
      expect(pr).to have_received(:set_build_status).with(:failure,
        "The proposal is blocked.", "groupthink/votes")
    end

    it "sets passed status" do
      allow(pr).to receive(:blocked?).and_return(false)
      allow(pr).to receive(:passed?).and_return(true)
      pr.__send__(:set_vote_build_status)
      expect(pr).to have_received(:set_build_status).with(:success,
        "The proposal has been agreed.", "groupthink/votes")
    end

    it "sets pending status" do
      allow(pr).to receive(:blocked?).and_return(false)
      allow(pr).to receive(:passed?).and_return(false)
      pr.__send__(:set_vote_build_status)
      expect(pr).to have_received(:set_build_status).with(:pending,
        "The proposal is waiting for more votes; 1 more needed.", "groupthink/votes")
    end
  end

  context "when setting time build status" do
    before do
      allow(pr).to receive(:set_build_status)
    end

    it "sets dead status" do
      allow(pr).to receive(:age).and_return(300)
      pr.__send__(:set_time_build_status)
      expect(pr).to have_received(:set_build_status).with(:failure,
        "The change has been open for more than 90 days, and should be closed (age: 300d).",
        "groupthink/time")
    end

    it "sets successful status" do
      allow(pr).to receive(:age).and_return(10)
      pr.__send__(:set_time_build_status)
      expect(pr).to have_received(:set_build_status).with(:success,
        "The change has been open long enough to be merged (age: 10d).",
        "groupthink/time")
    end

    it "sets waiting status" do
      allow(pr).to receive(:age).and_return(3)
      pr.__send__(:set_time_build_status)
      expect(pr).to have_received(:set_build_status).with(:pending,
        "The change has not yet been open for 7 days (age: 3d).",
        "groupthink/time")
    end
  end

  context "when checking for posted instructions" do
    it "can tell if instructions have already been posted" do
      comments = [
        instance_double("comment", body: "a comment"),
        instance_double("comment", body: "oh hai it's some <!-- votebot instructions --> wow"),
      ]
      expect(pr.__send__(:instructions_posted?, comments)).to be true
    end

    it "can tell if instructions are missing" do
      comments = [
        instance_double("comment", body: "no votebot instructions here"),
        instance_double("comment", body: "a comment"),
      ]
      expect(pr.__send__(:instructions_posted?, comments)).to be false
    end
  end

  context "when posting instructions" do
    before do
      allow(pr).to receive(:github_add_comment)
    end

    it "contains the magic comment for finding instruction blocks" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/<!-- votebot instructions -->/)
    end

    it "contains a link to the contributor list" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/\[contributor\]\(http:\/\/localhost:3000\/users\/\)/)
    end

    it "contains voting table with info on yes votes" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/|`:white_check_mark:`|1|/)
    end

    it "contains voting table with info on no votes" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/|`:negative_squared_cross_mark:`|-1|/)
    end

    it "contains voting table with info on block votes" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/|`:no_entry_sign:`|-1000|/)
    end

    it "contains details of pass threshold" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/Proposals will be accepted and merged once they have a total of 2 points/)
    end

    it "contains details of minimum age" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/Votes will be open for a minimum of 7 days/)
    end

    it "contains link to proposal page" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/\[automatically here\]\(http:\/\/localhost:3000\/proposals\/#{pr.number}\)/)
    end

    it "mentions the original author" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/@#{pr.proposer.login},/)
    end

    it "includes a link to edit the proposal files" do
      pr.__send__(:post_instructions)
      expect(pr).to have_received(:github_add_comment)
        .with(/here\]\(https:\/\/github.com\/openpolitics\/manifesto\/pull\/#{pr.number}\/files\)/)
    end
  end
end
