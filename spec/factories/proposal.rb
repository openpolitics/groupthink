FactoryGirl.define do

  factory :proposal do
    number { rand(1000) }
    state "waiting"
    title "Lorem Ipsum"
    #proposer - send this in
    opened_at { Time.now }

    after(:build) { |x| x.class.skip_callback(:validation, :before, :load_from_github) }
  end

end