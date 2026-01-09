# frozen_string_literal: true
FactoryBot.define do
  factory :oauth_token do
    service { "MyString" }
    endpoint { "MyString" }
    token { "MyString" }
    expiration_time { "2025-12-19 13:51:57" }
  end
end
