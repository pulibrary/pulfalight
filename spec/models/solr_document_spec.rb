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
