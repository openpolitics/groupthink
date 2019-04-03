# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  it "should fill in extra user data from github on creation" do
    login = "test"
    expect(Octokit).to receive(:user).with(login).and_return(
      OpenStruct.new({
        avatar_url: "https://example.com/avatar.png",
        email: "test@example.com"
      })
    )
    expect(Octokit).to receive(:contributors).and_return([
      OpenStruct.new({
        login: login
      })
    ])
    u = create :user_with_github_data, login: login
    expect(u.avatar_url).to eq "https://example.com/avatar.png"
    expect(u.email).to eq "test@example.com"
    expect(u.contributor).to eq true
  end
end
