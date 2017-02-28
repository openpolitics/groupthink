class ProposalsMailer < ApplicationMailer
  default_url_options[:host] = ENV["SITE_URL"]


  def new_proposal(recipient, proposal)
    @recipient = recipient
    @proposal = proposal
    mail to: recipient.email, subject: t("proposals_mailer.new.subject")
  end
end
