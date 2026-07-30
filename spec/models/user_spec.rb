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
      token = double("token", provider: "openid_connect", uid: "test@princeton.edu")
      user = described_class.from_omniauth(token)
      expect(user.uid).to eq "test"
      expect(user.provider).to eq "openid_connect"
      expect(user.email).to eq "test@princeton.edu"
    end

    it "updates an old CAS user" do
      user = FactoryBot.create(:user, provider: "cas")
      token = double("token", provider: "openid_connect", uid: user.email)

      described_class.from_omniauth(token)

      user = User.find(user.id)
      expect(user.provider).to eq "openid_connect"
    end
  end

  describe "#admin?" do
    context "with an admin user" do
      it "returns true" do
        user = FactoryBot.create(:admin)
        expect(user.admin?).to be true
      end
    end

    context "with a non-admin user" do
      it "returns false" do
        user = FactoryBot.create(:user)
        expect(user.admin?).to be false
      end
    end
  end
end
