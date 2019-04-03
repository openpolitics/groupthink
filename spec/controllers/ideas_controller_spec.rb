# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdeasController, type: :controller do
  describe "GET #index" do
    it "returns http success" do
      allow_any_instance_of(Octokit::Client).to receive(:issues).and_return([])
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns http success" do
      login = "test"
      allow_any_instance_of(Octokit::Client).to receive(:issue).with(ENV["GITHUB_REPO"], 430).and_return(
        OpenStruct.new(
          user: OpenStruct.new(
            login: login
          )
        )
      )
      expect(User).to receive(:find_or_create_by).with(login: login).and_return(create :user, login: login)
      allow_any_instance_of(Octokit::Client).to receive(:issue_comments).with(ENV["GITHUB_REPO"], 430).and_return([])
      get :show, params: { id: 430 }
      expect(response).to have_http_status(:success)
    end
  end
end
