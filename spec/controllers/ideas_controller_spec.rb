require 'rails_helper'

RSpec.describe IdeasController, type: :controller do

  describe "GET #index" do
    it "returns http success" do
      allow_any_instance_of(Octokit::Client).to receive(:issues).and_return([])
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns http success", :vcr do
      get :show, params: {id: 430}
      expect(response).to have_http_status(:success)
    end
  end

end
