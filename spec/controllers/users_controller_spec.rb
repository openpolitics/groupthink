# frozen_string_literal: true

require "rails_helper"

RSpec.describe UsersController, type: :controller do
  render_views

  let!(:user) { create :user, contributor: true, notify_new: true }

  context "when fetching user list page" do
    before do
      get :index
    end

    it "responds with 200" do
      expect(response).to be_ok
    end

    it "includes contributor list" do
      expect(response.body).to include "Contributors"
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
