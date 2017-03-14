require 'rails_helper'

RSpec.describe ProposalsController, type: :controller do
  render_views
  
  it "should show index page" do
    get :index
    expect(response).to be_ok
    expect(response.body).to include "https://openpolitics.org.uk"
  end

  it "should show individual proposal page", :vcr do
    # Stub out posting of instructions for now
    allow_any_instance_of(Proposal).to receive(:post_instructions)
    # Load a user
    User.create(login: 'Floppy')
    # Load a proposal
    Proposal.create(number: 405) # proposed by this user
    # Test show page
    get :show, params: {id: 405}
    expect(response).to be_ok
    expect(response.body).to include "Floppy"
  end

  context "adding comments" do
    
    before :each do
      @proposer = create :user, contributor: true, notify_new: true
      @proposal = create :proposal, proposer: @proposer
    end
    
    it "should redirect to login if not logged in" do
      put :comment, params: {id: @proposal.number}
      expect(response).to be_redirect
      expect(response.redirect_to).to include "/login"
    end
  
  end

end
