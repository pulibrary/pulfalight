# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  subject(:user) { described_class.new(uid: netid) }
  let(:netid) { "user" }

  it "uses the netid as the string representation" do
    expect(user.to_s).to eq(netid)
  end

  describe ".from_omniauth" do
    let(:retrieved_user) { instance_double(described_class) }
    # This models User::ActiveRecord_Relation
    let(:relation) { double }

    before do
      allow(relation).to receive(:first_or_create).and_yield(retrieved_user)
      allow(described_class).to receive(:where).and_return(relation)
      allow(retrieved_user).to receive(:uid=)
      allow(retrieved_user).to receive(:provider=)
      allow(retrieved_user).to receive(:email=)
    end

    it "creates a user" do
      token = double("token", provider: "cas", uid: "test")
      described_class.from_omniauth(token)
      expect(retrieved_user).to have_received(:uid=)
      expect(retrieved_user).to have_received(:provider=)
      expect(retrieved_user).to have_received(:email=)
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
