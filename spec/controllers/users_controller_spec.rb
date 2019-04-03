require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  render_views

  before :each do
    @user = create :user, contributor: true, notify_new: true
  end

  it "should show index page" do
    get :index
    expect(response).to be_ok
    expect(response.body).to include "Contributors"
    expect(response.body).to include @user.login
  end

  it "should show individual user page" do
    # Test show page
    get :show, params: { id: @user.login }
    expect(response).to be_ok
    expect(response.body).to include @user.login
  end
end
