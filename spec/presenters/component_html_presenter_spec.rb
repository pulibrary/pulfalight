# frozen_string_literal: true

require "rails_helper"
require "arclight/traject/nokogiri_namespaceless_reader"

RSpec.describe ComponentHtmlPresenter do
  subject(:presenter) { described_class.new(document) }

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
  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
  end
  let(:fixture_file) do
    File.read(fixture_path)
  end
  let(:nokogiri_reader) do
    Arclight::Traject::NokogiriNamespacelessReader.new(fixture_file.to_s, indexer.settings)
  end
  let(:xml_documents) do
    nokogiri_reader.to_a
  end
  let(:xml_document) do
    xml_documents.first
  end
  let(:values) do
    indexer.map_record(xml_document)
  end
  let(:document) { SolrDocument.new(values) }

  describe "#collection_notes" do
    it "generates the markup for the collection-level notes" do
      expect(presenter.collection_notes).to include("<p>Consists of two groups of material collected by Ferree: 1) copies of government reports,")
      expect(presenter.collection_notes).to include("</p>")
    end
  end
end
