class ProposalsMailer < ApplicationMailer

  def new_proposal(recipient, proposal)
    @recipient = recipient
    @proposal = proposal
    mail to: recipient.email, subject: t("proposals_mailer.new.subject")
  end
end
