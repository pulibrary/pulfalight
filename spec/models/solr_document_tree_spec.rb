# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolrDocumentTree do
  subject(:solr_document_tree) { described_class.new(root: solr_document) }

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
  let(:values) do
    indexer.map_record(record)
  end
  let(:solr_document) do
    SolrDocument.new(values)
  end

  context "when the Solr Document contains one or more member components" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC152.ead.xml")
    end

    describe "#children" do
      it "builds child SolrDocumentTree objects for each component" do
        expect(solr_document_tree.children).not_to be_empty
        expect(solr_document_tree.children.first).to be_a described_class
        expect(solr_document_tree.children.first.root).to be_a SolrDocument
        expect(solr_document_tree.children.first.root.id).to eq("aspace_MC152_c001")
        expect(solr_document_tree.children.last.root).to be_a SolrDocument
        expect(solr_document_tree.children.last.root.id).to eq("aspace_MC152_c043")
      end
    end
  end
end
