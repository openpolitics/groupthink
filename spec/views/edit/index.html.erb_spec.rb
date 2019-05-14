# frozen_string_literal: true

require "rails_helper"

RSpec.describe "edit/index.html.erb", type: :view do
  include Devise::Test::ControllerHelpers

  context "when logged out" do
    it "explains why the user should log in with GitHub" do
      render
      expect(rendered).to include("you need to log in with a free GitHub account")
    end
  end
end
