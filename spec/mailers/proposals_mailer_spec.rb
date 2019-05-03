# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalsMailer, type: :mailer do
  describe "new_proposal" do
    let(:proposer) { FactoryBot.create :user }
    let(:contributor) { FactoryBot.create :user, email: "contributor@example.com" }
    let(:proposal) { FactoryBot.create :proposal, proposer: contributor }
    let(:mail) { ProposalsMailer.new_proposal(contributor, proposal) }

    it "sends email to right person" do
      expect(mail.to).to eq(["contributor@example.com"])
    end

    it "sends email from specified domain" do
      expect(mail.from).to eq(["no-reply@#{ENV.fetch("EMAIL_DOMAIN")}"])
    end

    it "sets email subject" do
      expect(mail.subject).to eq("OpenPolitics Manifesto: new proposal ready for your vote")
    end

    it "includes title of proposal" do
      expect(mail.body.encoded).to match(proposal.title)
    end

    it "includes link to vote" do
      expect(mail.body.encoded).to match("#{ENV.fetch("SITE_URL")}/proposals/#{proposal.number}")
    end

    it "includes link to edit settings for user" do
      expect(mail.body.encoded).to match(/http.*\/users\/#{contributor.login}\/edit/)
    end
  end
end
