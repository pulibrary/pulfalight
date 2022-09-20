# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    sequence(:uid) { |_n| "username#{srand}" }
    sequence(:email) { |_n| "email-#{srand}@princeton.edu" }
    provider { "cas" }

    factory :admin do
      uid { "admin123" }
    end
  end
end
