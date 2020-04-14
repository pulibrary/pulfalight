# frozen_string_literal: true

require "rails_helper"

describe "controller requests", type: :request do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:file_path) { Rails.root.join("spec", "fixtures", "WC064_c1.json") }
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

  context "when an AJAX request is transmitted for a collection document" do
    before do
      allow(solr_response).to receive(:more_like).and_return([])
      allow(search_service).to receive(:fetch).and_return([solr_response, document])
      allow(Blacklight::SearchService).to receive(:new).and_return(search_service)
      headers = { "X-Requested-With" => "XMLHttpRequest" }
      get("/catalog/#{document.id}", headers: headers)
    end

    it "renders a minimal HTML template in the response" do
      expect(response.body).to include("<div id=\"document-minimal-#{document.id}\"")
      html_tree = Nokogiri::HTML(response.body)
      field_name_elements = html_tree.css("#document-minimal-#{document.id} span.field-name")
      expect(field_name_elements).not_to be_empty
      first_field_element = field_name_elements.first
      expect(first_field_element.text).to eq "id"
      second_field_element = field_name_elements[1]
      expect(second_field_element.text).to eq "level"

      field_value_elements = html_tree.css("#document-minimal-#{document.id} span.field-value")
      expect(field_value_elements).not_to be_empty
      first_field_element = field_value_elements.first
      expect(first_field_element.text).to eq "WC064"
      second_field_element = field_value_elements[1]
      expect(second_field_element.text).to eq "collection"
    end
  end
end
