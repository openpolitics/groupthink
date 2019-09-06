# frozen_string_literal: true

require "rails_helper"

# Make sure that https://nvd.nist.gov/vuln/detail/CVE-2015-9284 is mitigated
RSpec.describe "CVE-2015-9284", type: :request do
  after do
    ActionController::Base.allow_forgery_protection = @allow_forgery_protection
  end

  describe "GET /auth/:provider" do
    it do
      get user_github_omniauth_authorize_path
      expect(response).not_to have_http_status(:redirect)
    end
  end

  describe "POST /auth/:provider without CSRF token" do
    before do
      @allow_forgery_protection = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true
    end

    it do
      expect {
        post user_github_omniauth_authorize_path
      }.to raise_error(ActionController::InvalidAuthenticityToken)
    end
  end
end
