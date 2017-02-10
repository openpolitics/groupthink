FactoryGirl.define do

  factory :user do
    login { Faker::Internet.user_name }
    contributor true
    email { Faker::Internet.email }
    avatar_url { Faker::Internet.url }
    provider "github"
    
    after(:build) { |x| x.class.skip_callback(:validation, :before, :load_from_github) }
  end

end