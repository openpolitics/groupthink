# frozen_string_literal: true

# @!visibility private
class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{ENV['EMAIL_DOMAIN']}"
  layout "mailer"
end
