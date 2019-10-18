# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject(:user) { described_class.new(email: email) }
  let(:email) { "user@example.org" }

  it "uses the email address as the string representation" do
    expect(user.to_s).to eq(email)
  end
end
