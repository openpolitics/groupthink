describe User, :vcr do

  it "should load user data from github" do
    u = User.create(login: 'Floppy')
    expect(u.avatar_url).to be_present
    expect(u.email).to eq 'james@floppy.org.uk'
    expect(u.contributor).to eq true
  end

end
