# frozen_string_literal: true

require "rails_helper"
require "arclight/traject/nokogiri_namespaceless_reader"

RSpec.describe Arclight::SolrDocument do
  subject(:document) { SolrDocument.new(values) }

  let(:values) { {} }
  let(:indexer_settings) do
    {
      repository: "publicpolicy"
    }
  end
  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new(indexer_settings).tap do |i|
      i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
    end
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

  def find_component(component_id:, record:)
    return if record.blank?
    return record if record["id"][0] == component_id
    return if record["components"].blank?
    record["components"].each do |component|
      result = find_component(component_id: component_id, record: component)
      return result if result.present?
    end
    nil
  end

  describe "custom accessors" do
    it { expect(document).to respond_to(:parent_ids) }
    it { expect(document).to respond_to(:parent_labels) }
    it { expect(document).to respond_to(:eadid) }
  end

  describe "#collection?" do
    let(:file_path) do
      Rails.root.join("spec", "fixtures", "WC064.json")
    end
    let(:values) do
      fixture = File.read(file_path)
      JSON.parse(fixture)
    end

    it "determines whether or not a document is an EAD collection" do
      expect(document.collection?).to be true
    end
  end

  context "when the collection contains one or more member components" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC152.processed.EAD.xml")
    end
    let(:collection_values) do
      indexer.map_record(record)
    end
    let(:values) do
      collection_values["components"].first
    end

    describe "#component?" do
      it "determines whether or not a document is an EAD collection" do
        expect(document.component?).to be true
      end
    end

    describe "#html_presenter_class" do
      it "provides the Class used as a presenter for the SolrDocument" do
        expect(document.html_presenter_class).to eq(ComponentHtmlPresenter)
      end
    end
  end

  context "when the collection contains an encoded physical location" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC152.processed.EAD.xml")
    end
    let(:values) do
      indexer.map_record(record)
    end

    describe "#physical_locations" do
      it "accesses the encoded physical locations" do
        expect(document.physical_locations).not_to be_empty
        expect(document.physical_locations).to include("mudd")
      end
    end

    describe "#last_physical_location" do
      it "accesses the last encoded physical location" do
        expect(document.last_physical_location).to eq("mudd")
      end
    end
  end

  describe "#to_json" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end
    let(:values) do
      indexer.map_record(record)
    end
    let(:serialized) do
      document.to_json
    end
    it "builds the JSON for the Document" do
      expect(serialized).to be_a(String)
      expect(serialized).not_to be_empty

      built = JSON.parse(serialized)
      expect(built).to include("id" => "WC064")
      expect(built).to include("unittitle")
      expect(built["unittitle"]).not_to be_empty
      expect(built["unittitle"].first).to include("Princeton University Library Collection of Western Americana")
      expect(built).to include("has_digital_content")
      expect(built["has_digital_content"]).to be true

      expect(built).to include("components")
      expect(built["components"]).not_to be_empty
      first_child = built["components"].first
      expect(first_child).to include("id" => "WC064_c1")
      expect(first_child).to include("has_digital_content" => true)
    end
  end

  describe "#render_panopto?" do
    context "when then there's a panopto DAO" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC302.processed.EAD.xml") }
      it "returns true" do
        result = indexer.map_record(record)
        component = find_component(component_id: "MC302_c21357-52777", record: result)
        doc = SolrDocument.new(component)

        expect(doc.render_panopto?).to eq true
      end
    end
  end

  describe "#collection?" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end
    let(:values) do
      indexer.map_record(record)
    end
    let(:document) { SolrDocument.new(values) }

    it "determines whether or not a document is an EAD collection" do
      expect(document.collection?).to be true
    end
  end

  describe "#aeon_request" do
    it "returns an AeonRequest" do
      fixture = Rails.root.join("spec", "fixtures", "C1588.json")
      fixture = JSON.parse(fixture.read)
      component = fixture["components"].first["components"].first
      document = SolrDocument.new(component)

      request = document.aeon_request

      expect(request).to be_an AeonRequest
    end
  end
end
