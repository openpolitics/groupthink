require 'rails_helper'

RSpec.describe Proposal, :vcr do

  it "should include proposer information" do
    pr = Proposal.create(number: 43)
    expect(pr.proposer.login).to eq 'Floppy'
  end
  
  context "notification of new proposals" do
  
    before :all do
      @proposer = create :user, contributor: true, notify_new: true
      @voter = create :user, contributor: true, notify_new: true
      @no_notifications = create :user, contributor: true, notify_new: false
      @participant = create :user, contributor: false, notify_new: true
    end

    before :each do
      @mail = double("mail")
      allow(@mail).to receive(:deliver_now)
    end
  
    it "should go to voters" do
      expect(ProposalsMailer).to receive(:new_proposal).once do |user, proposal|
        expect(user).to eql @voter
        expect(proposal).to be_valid
        @mail
      end
      proposal = create :proposal, proposer: @proposer
    end
    
    it "should not go to proposer" do
      expect(ProposalsMailer).to receive(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql @proposer
        expect(proposal).to be_valid
        @mail
      end
      proposal = create :proposal, proposer: @proposer
    end

    it "should not go to a voter who has turned off notifications" do
      expect(ProposalsMailer).to receive(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql @no_notifications
        expect(proposal).to be_valid
        @mail
      end
      proposal = create :proposal, proposer: @proposer
    end

    it "should not go to people who don't have the vote" do
      expect(ProposalsMailer).to receive(:new_proposal).at_least(:once) do |user, proposal|
        expect(user).not_to eql @participant
        expect(proposal).to be_valid
        @mail
      end
      proposal = create :proposal, proposer: @proposer
    end

  end

end
