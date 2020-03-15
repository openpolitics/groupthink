# frozen_string_literal: true

# @!visibility private
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :store_current_location, unless: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :not_found_error

  protected
    def not_found_error
      render file: "public/404", status: :not_found
    end

    def user_github_connection
      Octokit::Client.new(access_token: session[:github_token])
    end

    def store_current_location
      if is_navigational_format?
        store_location_for(:user, request.url)
      end
    end
end
