# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalsMailer, type: :mailer do
  around do |example|
    ClimateControl.modify SITE_URL: "http://example.com", EMAIL_DOMAIN: "example.com" do
      example.run
    end
  end

  describe "new_proposal" do
    let(:proposer) { FactoryBot.create :user }
    let(:contributor) { FactoryBot.create :user, email: "contributor@mydomain.com" }
    let(:proposal) { FactoryBot.create :proposal, proposer: contributor }
    let(:mail) { ProposalsMailer.new_proposal(contributor, proposal) }

    it "sends email to right person" do
      expect(mail.to).to eq(["contributor@mydomain.com"])
    end

    it "sends email from specified domain" do
      expect(mail.from).to eq(["no-reply@example.com"])
    end

    it "sets email subject" do
      expect(mail.subject).to eq("OpenPolitics Manifesto: new proposal ready for your vote")
    end

    it "includes title of proposal" do
      expect(mail.body.encoded).to match(proposal.title)
    end

    it "includes link to vote" do
      expect(mail.body.encoded).to match("http://example.com/proposals/#{proposal.number}")
    end

    it "includes link to edit settings for user" do
      expect(mail.body.encoded).to match(/http.*\/users\/#{contributor.login}\/edit/)
    end
  end
end
