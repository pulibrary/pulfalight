# frozen_string_literal: true

require "rails_helper"

describe "controller requests", type: :request do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:file_path) { Rails.root.join("spec", "fixtures", "WC064_c1.json") }
  let(:document) do
    fixture_json = File.read(file_path)
    json = JSON.parse(fixture_json)
    SolrDocument.new(json, solr_response)
  end
  let(:search_service) { instance_double(Blacklight::SearchService) }

  before do
    allow(solr_response).to receive(:more_like).and_return([])
    allow(search_service).to receive(:fetch).and_return([solr_response, document])
    allow(Blacklight::SearchService).to receive(:new).and_return(search_service)
    get "/catalog/#{document.id}"
  end

  it "renders containers within component" do
    expect(response).to render_template(:show)
    expect(response.body).to include("Containers:")
    expect(response.body).to include("Folder h0001")
  end

  context "when requesting a collection with child components" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "WC064.json") }
    describe "/catalog/:id/raw" do
      before do
        get "/catalog/#{document.id}/raw"
      end

      it "renders the JSON serialization of the components" do
        expect(response.body).not_to be_empty
        json_body = JSON.parse(response.body)
        expect(json_body).to include("components")
        expect(json_body["components"]).not_to be_empty
      end
    end
  end
end
