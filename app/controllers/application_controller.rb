# frozen_string_literal: true

# @!visibility private
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end
