require 'spec_helper'

describe "index page" do
  
  it "should allow accessing the home page" do
    get '/'
    last_response.should be_ok
    last_response.body.should include "http://openpolitics.org.uk"
  end
  
end