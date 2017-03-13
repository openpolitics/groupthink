require 'rails_helper'

RSpec.describe IdeasController, type: :controller, vcr: true do

  describe "GET #index" do
    it "returns http success" do
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET #show" do
    it "returns http success" do
      get :show, id: 430
      expect(response).to have_http_status(:success)
    end
  end

end
