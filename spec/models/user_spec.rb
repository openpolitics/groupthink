# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
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

  it "fills in extra user data from github on creation" do
    u = create :user_with_github_data, login: login
    expect(u.avatar_url).to eq "https://example.com/avatar.png"
    expect(u.email).to eq "test@example.com"
    expect(u.contributor).to eq true
  end
end
