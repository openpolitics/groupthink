require "rails_helper"

RSpec.describe ProposalsMailer, type: :mailer do
  describe "new_proposal" do
    
    let(:proposer) { FactoryGirl.create :user }
    let(:contributor) { FactoryGirl.create :user, email: "contributor@example.com" }
    let(:proposal) { FactoryGirl.create :proposal, proposer: contributor }
    let(:mail) { ProposalsMailer.new_proposal(contributor, proposal) }
  
    it "renders the headers" do
      expect(mail.to).to eq(["contributor@example.com"])
      expect(mail.from).to eq(["no-reply@#{ENV["EMAIL_DOMAIN"]}"])
      expect(mail.subject).to eq("OpenPolitics Manifesto: new proposal ready for your vote")
    end
  
    it "should include title of proposal" do
      expect(mail.body.encoded).to match(proposal.title)
    end

    it "should include link to vote" do
      expect(mail.body.encoded).to match("https://github.com/#{ENV["GITHUB_REPO"]}/pull/#{proposal.number}")
    end

    it "should include link to edit settings for user" do
      expect(mail.body.encoded).to match(/http.*\/users\/#{contributor.login}\/edit/)
    end

  end

end
