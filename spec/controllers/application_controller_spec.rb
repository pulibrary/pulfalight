# frozen_string_literal: true
require "rails_helper"

describe ApplicationController, type: :controller do
  describe "#guest_uid_authentication_key" do
    let(:key) { "public_user" }

    it "prepends 'guest_' to auth. keys if the user does not have a uid" do
      expect(controller.guest_uid_authentication_key(key)).to match(/^guest_/)
    end
  end

  describe "rescuing a non xml routing error" do
    # Raise error on index. Currently, there is no URL which will trigger this
    # error outside of an "xml report error". However, it is a useful fallback
    # that might catch errors in the future.
    controller do
      def index
        raise ActionController::RoutingError, "no route matches"
      end
    end

    it "renders the 404 page" do
      get :index
      expect(response).to have_http_status(:not_found)
    end
  end
end
