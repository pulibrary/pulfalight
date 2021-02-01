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

  describe "/catalog/:id JSON" do
    context "for a component" do
      it "renders sufficient JSON for Figgy to use" do
        get "/catalog/WC064_c1.json"
        json_body = JSON.parse(response.body)

        expect(json_body["title"]).to eq ["American Indian man wearing traditional clothing with three white children"]
        expect(json_body["language"]).to eq ["English"]
        expect(json_body["date_created"]).to eq ["1850-1860"]
        expect(json_body["created"]).to eq ["1850-1860"]
        expect(json_body["extent"]).to eq ["1 folder; 10 x 7 cm."]
        expect(json_body["container"]).to eq ["Box h1, Folder h0001"]
        expect(json_body["heldBy"]).to eq ["Firestone Library"]
        expect(json_body["creator"]).to eq "Princeton University. Library. Special Collections"
        expect(json_body["publisher"]).to eq ["Princeton University. Library. Special Collections"]
        expect(json_body["memberOf"]).to eq [
          {
            "title" => "Princeton University Library Collection of Western Americana Photographs, 1840-1998, bulk 1870/1915",
            "identifier" => "WC064"
          }
        ]
      end
      it "renders just the location code if it can't find a string" do
        allow(Pulfalight::LocationCode).to receive(:registered?).and_return(false)
        get "/catalog/WC064_c1.json"
        json_body = JSON.parse(response.body)

        expect(json_body["heldBy"]).to eq ["mss"]
      end
    end
    context "for a collection" do
      it "renders sufficient JSON for Figgy to use" do
        get "/catalog/WC064.json"
        json_body = JSON.parse(response.body)

        expect(json_body["title"]).to eq ["Princeton University Library Collection of Western Americana Photographs"]
        expect(json_body["language"]).to eq ["English"]
        expect(json_body["date_created"]).to eq ["1840-1998, bulk 1870/1915"]
        expect(json_body["created"]).to eq ["1840/1998"]
        expect(json_body["extent"]).to eq ["144 boxes", "123 linear feet"]
        expect(json_body["heldBy"]).to eq ["Firestone Library"]
        expect(json_body["memberOf"]).to be_nil
      end
    end
  end
end
