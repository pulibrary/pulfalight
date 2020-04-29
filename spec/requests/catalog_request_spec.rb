# frozen_string_literal: true

require "rails_helper"

describe "controller requests", type: :request do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "WC064.json") }
  let(:fixture_json) { File.read(fixture_file_path) }
  let(:document) do
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

  context "when requesting to view a component" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "WC064_c1.json") }

    it "renders containers within component" do
      expect(response).to render_template(:show)
      expect(response.body).to include("Containers:")
      expect(response.body).to include("Folder h0001")
    end
  end

  context "when requesting a JSON serialization of the Document" do
    before do
      get("/catalog/#{document.id}", params: { format: :json })
    end
    it "generates the JSON object" do
      expect(response.body).not_to be_empty
      json_body = JSON.parse(response.body)
      expect(json_body).to include("id")
      expect(json_body["id"]).to include("WC064")
    end
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
      field_name_elements = html_tree.css("#document-minimal-#{document.id} .document-minimal-field-name")
      expect(field_name_elements).not_to be_empty
      first_field_element = field_name_elements.first
      expect(first_field_element.text).to eq "id"
      second_field_element = field_name_elements[1]
      expect(second_field_element.text).to eq "has_digital_content"

      field_value_elements = html_tree.css("#document-minimal-#{document.id} .document-minimal-field-value")
      expect(field_value_elements).not_to be_empty
      first_field_element = field_value_elements.first
      expect(first_field_element.text).to eq "WC064"
      second_field_element = field_value_elements[1]
      expect(second_field_element.text).to eq "true"

      component_field_elements = field_name_elements.select { |element| element.text == "components" }
      expect(component_field_elements).not_to be_empty
      component_field_element = component_field_elements.first
      component_tree_element = component_field_element.parent
      child_component_elements = component_tree_element.css("#document-minimal-WC064_c1")
      expect(child_component_elements).not_to be_empty
    end

    context "when requesting a component with child component nodes" do
      let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "WC064_c1.json") }

      it "renders a minimal HTML template in the response without child components" do
        expect(response.body).to include("<div id=\"document-minimal-#{document.id}\"")
        html_tree = Nokogiri::HTML(response.body)
        field_name_elements = html_tree.css("#document-minimal-#{document.id} .document-minimal-field-name")
        expect(field_name_elements).not_to be_empty

        component_field_elements = field_name_elements.select { |element| element.text == "components" }
        expect(component_field_elements).not_to be_empty
        component_field_element = component_field_elements.first
        component_tree_element = component_field_element.parent
        child_component_elements = component_tree_element.css(".document-minimal-field-value")
        expect(child_component_elements).to be_empty
      end
    end
  end
end
