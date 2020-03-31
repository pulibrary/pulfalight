# frozen_string_literal: true
require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "#current_year" do
    it "returns the current year" do
      expect(helper.current_year).to eq DateTime.current.year
    end
  end

  describe "#guest_uid_authentication_key" do
    let(:key) { "public_user" }

    it "prepends 'guest_' to auth. keys if the user does not have a uid" do
      expect(helper.guest_uid_authentication_key(key)).to eq("guest_foo")
    end
  end
end
