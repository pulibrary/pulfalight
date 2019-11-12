# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject(:user) { described_class.new(uid: netid) }
  let(:netid) { "user" }

  it "uses the netid as the string representation" do
    expect(user.to_s).to eq(netid)
  end

  describe ".from_omniauth" do
    it "creates a user" do
      token = double("token", provider: "cas", uid: "test")
      user = described_class.from_omniauth(token)
      expect(user).to be_persisted
      expect(user.provider).to eq "cas"
      expect(user.uid).to eq "test"
    end
  end
end
