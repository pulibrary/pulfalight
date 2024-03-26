# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Errors", type: :request do
  describe "unmatched routes" do
    before(:all) { get "/nonexistent_resource" }

    it "has an http status of 404" do
      expect(response).to have_http_status(:not_found)
    end

    it "redirects to the custom not_found error page" do
      expect(response.body).to include("The page you were looking for doesn't exist.")
    end
  end

  # Blacklight::Exceptions::RecordNotFound
  describe "record not found" do
    context "for an html request" do
      it "renders a 404 page" do
        params = { id: "unknown_work" }
        get "/catalog/#{params[:id]}"

        expect(response.status).to eq(404)
        expect(response.body).to include("The page you were looking for doesn't exist.")
        expect(response.body).to include("unknown_work")
      end
    end

    context "for an xml request" do
      it "renders a 404" do
        params = { id: "unknown_work" }
        get "/catalog/#{params[:id]}.xml"

        expect(response.status).to eq(404)
        expect(response.body).to include("The resource you were looking for doesn't exist.")
      end
    end
  end
end
