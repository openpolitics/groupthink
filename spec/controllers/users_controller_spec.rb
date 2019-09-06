# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :controller do
  render_views

  let!(:user) { create :user, author: true, notify_new: true }

  around do |example|
    env = {
      PROJECT_NAME: "Test Project",
      PROJECT_URL: "http://project.example.com",
      SITE_URL: "http://groupthink.example.com",
    }
    ClimateControl.modify env do
      example.run
    end
  end

  context "when fetching user list page" do
    before do
      get :index
    end

    it "responds with 200" do
      expect(response).to be_ok
    end

    it "includes author list" do
      expect(response.body).to include "Authors"
    end

    it "includes current user" do
      expect(response.body).to include user.login
    end
  end

  context "when fetching individual user page" do
    before do
      get :show, params: { id: user.login }
    end

    it "responds with 200" do
      expect(response).to be_ok
    end

    it "includes user login in page" do
      expect(response.body).to include user.login
    end
  end
end
