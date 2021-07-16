# frozen_string_literal: true

# @!visibility private
class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{Rails.application.config.groupthink[:email_domain]}"
  layout "mailer"
end
