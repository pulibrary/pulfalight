# frozen_string_literal: true
require "rails_helper"

describe "controller requests", type: :request do
  describe "/catalog/:id/raw" do
    it "renders a raw Solr JSON document" do
      get "/catalog/WC064/raw"
      expect(response.body).not_to be_empty
      json_body = JSON.parse(response.body)
      expect(json_body).to include("id" => "WC064")
      expect(json_body).to include("title_ssm" => ["Princeton University Library Collection of Western Americana Photographs"])
    end
  end
end
