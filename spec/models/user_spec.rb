# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  let!(:login) { "test" }
  let!(:mock_user) {
    OpenStruct.new(
      avatar_url: "https://example.com/avatar.png",
      email: "test@example.com"
    )
  }
  let!(:mock_contributors) {
    [
      OpenStruct.new(
        login: login
      )
    ]
  }
  let!(:mock_permissions) {
    OpenStruct.new(
      permission: "admin"
    )
  }

  around do |example|
    env = {
      GITHUB_REPO: "example/repo"
    }
    ClimateControl.modify env do
      example.run
    end
  end

  before do
    allow(Octokit).to receive(:user).with(login).and_return(mock_user)
    allow(Octokit).to receive(:contributors).and_return(mock_contributors)
    allow(Octokit).to receive(:permission_level).and_return(mock_permissions)
  end

  context "when filling in extra user data from github on creation" do
    let(:u) { create :user_with_github_data, login: login }

    it "sets avatar URL" do
      expect(u.avatar_url).to eq "https://example.com/avatar.png"
    end

    it "sets email" do
      expect(u.email).to eq "test@example.com"
    end

    it "sets author state" do
      expect(u.author).to eq true
    end

    it "sets role" do
      expect(u.admin?).to eq true
    end
  end

  context "when checking if a user can vote" do
    it "allows voting if the voter flag is true" do
      user = create :user, voter: true
      expect(user.can_vote?).to eq true
    end

    it "doesn't allows voting if the voter flag is false" do
      user = create :user, voter: false
      expect(user.can_vote?).to eq false
    end

    it "doesn't allow authors to vote by default" do
      user = create :user, author: true
      expect(user.can_vote?).to eq false
    end

    it "allows authors to vote if ALL_AUTHORS_CAN_VOTE is true" do
      ClimateControl.modify ALL_AUTHORS_CAN_VOTE: "true" do
        user = create :user, author: true
        expect(user.can_vote?).to eq true
      end
    end

    it "doesn't allow non-authors to vote even if ALL_AUTHORS_CAN_VOTE is true" do
      ClimateControl.modify ALL_AUTHORS_CAN_VOTE: "true" do
        user = create :user, author: false
        expect(user.can_vote?).to eq false
      end
    end
  end
end
