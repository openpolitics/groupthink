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

  before do
    allow(Octokit).to receive(:user).with(login).and_return(mock_user)
    allow(Octokit).to receive(:contributors).and_return(mock_contributors)
  end

  context "when filling in extra user data from github on creation" do
    let(:u) { create :user_with_github_data, login: login }

    it "sets avatar URL" do
      expect(u.avatar_url).to eq "https://example.com/avatar.png"
    end

    it "sets email" do
      expect(u.email).to eq "test@example.com"
    end

    it "sets contributor state" do
      expect(u.contributor).to eq true
    end
  end
end
