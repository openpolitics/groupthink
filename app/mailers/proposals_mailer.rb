# frozen_string_literal: true

#
# Sends emails for updates to proposals
#
class ProposalsMailer < ApplicationMailer
  def new_proposal(recipient, proposal)
    default_url_options[:host] = ENV.fetch("SITE_URL")
    @recipient = recipient
    @proposal = proposal
    mail to: recipient.email, subject: t("proposals_mailer.new.subject")
  end
end
