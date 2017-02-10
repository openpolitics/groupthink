FactoryGirl.define do

  factory :proposal do
    number { Faker::Number.number(3) }
    state "waiting"
    title { Faker::Book.title }
    #proposer - send this in
    opened_at { Time.now }

    # Don't run load_from_github callback when creating from factory, but put it back after
    after(:build) { |x| x.class.skip_callback(:validation, :before, :load_from_github) }
    after(:create) { |x| x.class.set_callback(:validation, :before, :load_from_github, on: :create)}
  end

end