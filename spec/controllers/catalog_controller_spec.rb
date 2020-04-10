# frozen_string_literal: true
require "rails_helper"

describe CatalogController, type: :controller do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "WC064_c1.json") }
  let(:document) do
    fixture_json = File.read(fixture_file_path)
    json = JSON.parse(fixture_json)
    SolrDocument.new(json, solr_response)
  end
  let(:search_service) { instance_double(Blacklight::SearchService) }

  before do
    allow(solr_response).to receive(:more_like).and_return([])
    allow(search_service).to receive(:fetch).and_return([solr_response, document])
    allow(Blacklight::SearchService).to receive(:new).and_return(search_service)
  end

  describe "#item_requestable?" do
    let(:options) do
      {
        document: document
      }
    end
    let(:output) { controller.item_requestable?(nil, options) }

    it "determines whether or not an item can be requested through Aeon" do
      expect(output).to eq(true)
    end

    context "when the item is a collection" do
      let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002.json") }
      it "users cannot request the item from Aeon" do
        expect(output).to eq(false)
      end
    end
  end
end
