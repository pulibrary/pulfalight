# frozen_string_literal: true

require "rails_helper"

describe "controller requests", type: :request do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:settings) do
    {
      repository: "mss"
    }
  end
  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new(settings).tap do |i|
      i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
    end
  end
  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "ead", "mss", "C1588.EAD.xml")
  end
  let(:fixture_file) do
    File.read(fixture_path)
  end
  let(:nokogiri_reader) do
    Arclight::Traject::NokogiriNamespacelessReader.new(fixture_file.to_s, indexer.settings)
  end
  let(:records) do
    nokogiri_reader.to_a
  end
  let(:record) do
    records.first
  end
  let(:solr_values) do
    indexer.map_record(record)
  end
  let(:document) do
    parent = SolrDocument.new(solr_values, solr_response)
    child_values = parent["components"].find { |c| c["id"].first == "C1588_c15" }
    SolrDocument.new(child_values, solr_response)
  end
  let(:search_service) { instance_double(Blacklight::SearchService) }
  let(:document_id) { "C1588_c15" }

  before do
    allow(solr_response).to receive(:more_like).and_return([])
    allow(search_service).to receive(:fetch).and_return([solr_response, document])
    allow(Blacklight::SearchService).to receive(:new).and_return(search_service)
    get "/catalog/#{document_id}"
  end

  context "when requesting to view a component" do
    it "renders containers within component" do
      expect(response).to render_template(:show)
      expect(response.body).to include("Containers:")
      expect(response.body).to include("Folder 11")
    end
  end

  context "when requesting a JSON serialization of the Document" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mss", "WC064_pruned.EAD.xml")
    end
    let(:document) do
      SolrDocument.new(solr_values, solr_response)
    end

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
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mss", "WC064_pruned.EAD.xml")
    end
    let(:document) do
      SolrDocument.new(solr_values, solr_response)
    end

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
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "ead", "mss", "WC064_pruned.EAD.xml")
      end
      let(:document) do
        SolrDocument.new(solr_values, solr_response)
      end

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
        expect(child_component_elements).not_to be_empty
        expect(child_component_elements.first.text).to eq("WC064_c1")
      end
    end
  end

  it "renders containers within component" do
    expect(response).to render_template(:show)
    expect(response.body).to include("Containers:")
    expect(response.body).to include("Folder 11")
  end

  context "when the collection repository has citation formatting configured" do
    let(:settings) do
      {
        repository: "publicpolicy"
      }
    end
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC221.EAD.xml")
    end
    let(:document_id) { Array.wrap(document.id).first }
    let(:document) do
      SolrDocument.new(solr_values, solr_response)
    end

    it "renders the preferred citation for the collection" do
      expect(response).to render_template(:show)
      expect(response.body).to include("PREFERRED CITATION:")
      expect(response.body).to include("Harold B. Hoskins Papers; Public Policy Papers, Department of Special Collections, Princeton University Library")
    end
  end

  describe "searching all collections" do
    let(:query) { "C1588" }

    before do
      repository = Blacklight.default_index
      repository.connection.add(document)
      repository.connection.commit

      allow(Blacklight::SearchService).to receive(:new).and_call_original
    end

    after do
      repository = Blacklight.default_index
      repository.connection.delete_by_id(document.id)
      repository.connection.commit
    end

    context "when searching for a specific collection by ID" do
      it "directs the user to the exact collection if it exists" do
        get "/catalog?q=#{query}"
        expect(response).to redirect_to(solr_document_url(document.id))
      end

      it "directs the user to the search results if it does not exist" do
        get "/catalog?q=WC063"
        expect(response.body).to include("Search Results")
      end
    end
  end
end
