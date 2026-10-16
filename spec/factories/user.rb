# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    sequence(:uid) { |_n| "username#{srand}" }
    email { "#{uid}@princeton.edu" }
    provider { "openid_connect" }

    factory :admin do
      uid { "admin123" }
    end
  end
end
