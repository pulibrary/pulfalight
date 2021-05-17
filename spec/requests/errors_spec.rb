# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Errors", type: :request do
  describe ":not found" do
    before(:all) { get "/nonexistent_resource" }

    it "has an http status of 404" do
      expect(response).to have_http_status(:not_found)
    end

    it "redirects to the custom not_found error page" do
      expect(response.body).to include("The page you were looking for doesn't exist.")
    end
  end
end
