# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController do
  let(:user) do
    User.new(
      provider: "cas",
      uid: "user@princeton.edu"
    )
  end

  before do
    request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe "logging in" do
    it "valid CAS login redirects to account page" do
      allow(User).to receive(:from_omniauth).and_return(user)
      get(:cas)
      expect(response).to redirect_to("http://test.host/")
    end
  end
end
