require 'rails_helper'

RSpec.describe ProposalsController, type: :controller do
  render_views
  
  it "should show index page" do
    get :index
    expect(response).to be_ok
    expect(response.body).to include "http://openpolitics.org.uk"
  end

end
