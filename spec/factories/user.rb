# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    login { Faker::Internet.user_name }
    contributor { true }
    email { Faker::Internet.email }
    avatar_url { Faker::Internet.url }
    provider { "github" }

    # Don't run load_from_github callback when creating from factory, but put it back after
    after(:build) { |x| x.class.skip_callback(:validation, :before, :load_from_github) }
    after(:create) { |x| x.class.set_callback(:validation, :before, :load_from_github, on: :create) }
  end

  factory :user_with_github_data, class: User do
    login { Faker::Internet.user_name }
    provider { "github" }
  end
end
