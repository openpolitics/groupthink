# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditController, type: :controller do
  context "when user isn't logged in" do
    it "sends the user to log in when they try to make a new file" do
      get :new, params: { branch: "master" }
      expect(response).to redirect_to("/edit")
    end

    it "sends the user to log in when they try to make an edit" do
      get :edit, params: { branch: "master", path: "test.md" }
      expect(response).to redirect_to("/edit")
    end
  end
end
