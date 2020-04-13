# frozen_string_literal: true

require "rails_helper"

describe "controller requests", type: :request do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:document) do
    file_path = Rails.root.join("spec", "fixtures", "WC064.json")
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
end
