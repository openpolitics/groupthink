# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdeasController, type: :controller do
  around do |example|
    env = {
      GITHUB_REPO: "example/repo"
    }
    ClimateControl.modify env do
      example.run
    end
  end

  describe "GET #index" do
    before do
      allow(Octokit).to receive(:issues).and_return([])
    end

    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    let(:login) { "test" }

    before do
      allow(Octokit).to receive(:issue).and_return(
        OpenStruct.new(
          user: OpenStruct.new(
            login: login
          )
        )
      )
      allow(User).to receive(:find_or_create_by!)
        .with(login: login)
        .and_return(create :user, login: login)
      allow(Octokit).to receive(:issue_comments).and_return([])
    end

    it "returns http success" do
      get :show, params: { id: 123 }
      expect(response).to have_http_status(:success)
    end
  end
end
