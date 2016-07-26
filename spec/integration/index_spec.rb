RSpec.describe "index page" do
  
  it "should allow accessing the home page" do
    get '/'
    expect(response).to be_ok
    expect(response.body).to include "http://openpolitics.org.uk"
  end
  
end