# frozen_string_literal: true
require "rails_helper"

describe "multiple algorithms", type: :request do
  describe "search algorithm selection" do
    before do
      allow(Pulfalight).to receive(:multiple_algorithms_enabled?).and_return(true)
    end

    context "when the search_algorithm parameter is not present" do
      it "ranks using the default request handler" do
        get "/catalog.json?q=diary&search_field=all_fields"
        json = JSON.parse(response.body)

        expect(json["data"][0]["id"]).to eq "C1387"
      end
    end

    context "when the search_algorithm parameter is set to 'online_content'" do
      it "ranks using the online_content request handler" do
        # Expected: /catalog.json?f%5Bhas_direct_online_content_ssim%5D%5B%5D=online&q=diary&search_field=all_fields
        get "/catalog.json?q=diary&search_field=all_fields&search_algorithm=online_content"
        json = JSON.parse(response.body)

        expect(json["data"][0]["id"]).to eq "MC221_c0094"
      end
    end
  end
end
