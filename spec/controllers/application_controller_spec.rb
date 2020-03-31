# frozen_string_literal: true
require "rails_helper"

describe ApplicationController, type: :controller do
  describe "#guest_uid_authentication_key" do
    let(:key) { "public_user" }

    it "prepends 'guest_' to auth. keys if the user does not have a uid" do
      expect(controller.guest_uid_authentication_key(key)).to match(/^guest_/)
    end
  end
end
