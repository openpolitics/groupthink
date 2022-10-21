# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProposalsMailer, type: :mailer do
  around do |example|
    ClimateControl.modify SITE_URL: "http://example.com", EMAIL_DOMAIN: "example.com" do
      example.run
    end
  end

  describe "new_proposal" do
    let(:proposer) { create :user }
    let(:voter) { create :user, email: "voter@mydomain.com" }
    let(:proposal) { create :proposal, proposer: voter }
    let(:mail) { described_class.new_proposal(voter, proposal) }

    it "sends email to right person" do
      expect(mail.to).to eq(["voter@mydomain.com"])
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
      expect(mail.body.encoded).to match(/http.*\/users\/#{voter.login}\/edit/)
    end
  end
end
