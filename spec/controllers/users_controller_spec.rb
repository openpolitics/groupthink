require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  render_views
  
  it "should show index page" do
    get :index
    expect(response).to be_ok
    expect(response.body).to include "Contributors"
  end

  it "should show individual user page", :vcr do
    # Stub out posting of instructions for now
    allow_any_instance_of(Proposal).to receive(:post_instructions)
    # Load a user
    User.create(login: 'Floppy')
    # Load a few proposals
    Proposal.create(number: 405) # proposed by this user
    Proposal.create(number: 100) # voted on by this user
    # Test show page
    get :show, params: {id: 'Floppy'}
    expect(response).to be_ok
    expect(response.body).to include "Floppy"
  end

end
