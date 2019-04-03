FactoryBot.define do

  factory :proposal do
    number { Faker::Number.number(3) }
    state "waiting"
    title { Faker::Book.title }
    proposer { create :user }
    opened_at { Time.now }

    # Don't run load_from_github callback when creating from factory, but put it back after
    after(:build) do |x|
      x.class.skip_callback(:validation, :before, :load_from_github)
      x.class.skip_callback(:create, :after, :queue_vote_count)
    end
    after(:create) do |x|
      x.class.set_callback(:create, :after, :queue_vote_count)
      x.class.set_callback(:validation, :before, :load_from_github, on: :create)
    end
  end

end
