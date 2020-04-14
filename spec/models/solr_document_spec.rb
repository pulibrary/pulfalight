# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arclight::SolrDocument do
  let(:values) { {} }
  let(:document) { SolrDocument.new(values) }

  describe "custom accessors" do
    it { expect(document).to respond_to(:parent_ids) }
    it { expect(document).to respond_to(:parent_labels) }
    it { expect(document).to respond_to(:eadid) }
  end

  describe "#to_json" do
    let(:file_path) do
      Rails.root.join("spec", "fixtures", "WC064.json")
    end
    let(:values) do
      fixture = File.read(file_path)
      JSON.parse(fixture)
    end
    let(:document) { SolrDocument.new(values) }
    let(:serialized) { document.to_json }
    it "builds the JSON for the Document" do
      expect(serialized).to be_a(String)
      expect(serialized).not_to be_empty

      built = JSON.parse(serialized)
      expect(built).to include("id" => "WC064")
      expect(built).to include("level" => "collection")
      expect(built).to include("creator" => "Princeton University Library. Special Collections.")
      expect(built).to include("abstract")
      expect(built["abstract"]).not_to be_empty
      expect(built["abstract"].first).to include("An open collection of more than 5,000 Western Americana photographs,")
      expect(built).to include("extent" => "123 linear feet")
      expect(built).to include("unitid" => "WC064")
      expect(built).to include("eadid" => ["WC064"])
      expect(built).to include("ead" => ["WC064"])
      expect(built).to include("title")
      expect(built["title"]).not_to be_empty
      expect(built["title"].first).to include("Princeton University Library Collection of Western Americana")
      expect(built).to include("names")
      expect(built["names"]).not_to be_empty
      expect(built["names"].first).to include("Princeton University Library. Special Collections.")
      expect(built["names"].last).to include("Luck, Owen Craig,")

      expect(built).to include("corpname")
      expect(built["corpname"]).not_to be_empty
      expect(built["corpname"].first).to include("Princeton University Library. Special Collections.")
      expect(built["corpname"].last).to include("Stewart Brothers")

      expect(built).to include("geogname")
      expect(built["geogname"]).not_to be_empty
      expect(built["geogname"].first).to include("West (U.S.) -- Photographs.")

      expect(built).to include("places")
      expect(built["places"]).not_to be_empty
      expect(built["places"].first).to include("West (U.S.) -- Photographs.")

      expect(built).to include("access_subjects")
      expect(built["access_subjects"]).not_to be_empty
      expect(built["access_subjects"].first).to include("Indians of Central America -- Photographs.")
      expect(built["access_subjects"].last).to include("Photographs.")

      expect(built).to include("acqinfo")
      expect(built["acqinfo"]).not_to be_empty
      expect(built["acqinfo"].first).to include("This is an open collection that continually grows from gifts and purchases.")

      expect(built).to include("components")
      expect(built["components"]).not_to be_empty
      first_child = built["components"].first
      expect(first_child).to include("id" => "WC064_c1")
    end
  end

  describe "#collection?" do
    let(:file_path) do
      Rails.root.join("spec", "fixtures", "WC064.json")
    end
    let(:values) do
      fixture = File.read(file_path)
      JSON.parse(fixture)
    end
    let(:document) { SolrDocument.new(values) }

    it "determines whether or not a document is an EAD collection" do
      expect(document.collection?).to be true
    end
  end
end
