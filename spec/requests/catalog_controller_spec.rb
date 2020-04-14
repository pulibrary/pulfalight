# frozen_string_literal: true

require "rails_helper"

describe "controller requests", type: :request do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:document) do
    file_path = Rails.root.join("spec", "fixtures", "WC064_c1.json")
    fixture_json = File.read(file_path)
    json = JSON.parse(fixture_json)
    SolrDocument.new(json, solr_response)
  end
  let(:search_service) { instance_double(Blacklight::SearchService) }

  before do
    allow(solr_response).to receive(:more_like).and_return([])
    allow(search_service).to receive(:fetch).and_return([solr_response, document])
    allow(Blacklight::SearchService).to receive(:new).and_return(search_service)
  end

  describe "/catalog/:id/raw" do
    before do
      get "/catalog/#{document.id}/raw"
    end

    it "renders a JSON serialization of the document" do
      expect(response.body).not_to be_empty
      json_body = JSON.parse(response.body)
      expect(json_body).to include("id" => "WC064_c1")
      expect(json_body).to include("ead" => "WC064")
      expect(json_body).to include("title" => ["American Indian man wearing traditional clothing with three white\n                        children"])
    end
  end
end
