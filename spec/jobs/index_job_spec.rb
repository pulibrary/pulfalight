# frozen_string_literal: true
require "rails_helper"

describe IndexJob do
  describe IndexJob::EADArray do
    subject(:ead_array) { described_class.new }

    describe "#put" do
      let(:traject_hash) do
        { foo: :bar }
      end
      let(:traject_context) { instance_double(Traject::Indexer::Context) }

      it "appends the hash generated from a Traject::Indexer::Context object" do
        allow(traject_context).to receive(:output_hash).and_return(traject_hash)

        ead_array.put(traject_context)
        expect(ead_array.last).to eq(traject_hash)
      end
    end
  end

  let(:file_paths) do
    [
      Rails.root.join("spec", "fixtures", "ead", "rarebooks", "WC127.EAD.xml")
    ]
  end
  let(:connection) { instance_double(RSolr::Client) }
  let(:default_index) { instance_double(Blacklight::Solr::Repository) }
  let(:solr_document) do
    {
      "ead_ssi" => ["WC127"],
      "id" => ["WC127"],
      "level_ssm" => ["collection"],
      "title_ssm" => ["Wanted Outlaws Posters Collection"],
      "unitid_ssm" => ["WC127"],
      "components" => []
    }
  end
  let(:solr_documents) do
    [
      solr_document
    ]
  end
  let(:indexer) { instance_double(Traject::Indexer::NokogiriIndexer) }

  describe "#arclight_config_path" do
    let(:indexer) { described_class.new }

    it "generates the path for Traject configuration" do
      expect(indexer.arclight_config_path).to include("pulfalight/lib/pulfalight/traject/ead2_config.rb")
    end
  end

  describe "#indexer" do
    let(:nokogiri_indexer) { instance_double(Traject::Indexer::NokogiriIndexer) }
    let(:indexer) { described_class.new }

    before do
      allow(nokogiri_indexer).to receive(:load_config_file)
      allow(nokogiri_indexer).to receive(:tap).and_yield(nokogiri_indexer)
      allow(Traject::Indexer::NokogiriIndexer).to receive(:new).and_return(nokogiri_indexer)
      indexer.indexer
    end

    it "constructs a Traject indexer with the custom configuration" do
      expect(nokogiri_indexer).to have_received(:load_config_file).with(/ead2_config\.rb/)
    end
  end

  describe "#perform" do
    before do
      allow(described_class::EADArray).to receive(:new).and_return(solr_documents)
      allow(indexer).to receive(:process_with)
      allow(indexer).to receive(:tap).and_return(indexer)
      allow(Traject::Indexer::NokogiriIndexer).to receive(:new).and_return(indexer)
      allow(connection).to receive(:commit)
      allow(connection).to receive(:add)
      allow(default_index).to receive(:connection).and_return(connection)
      allow(Blacklight).to receive(:default_index).and_return(default_index)

      described_class.perform_now(file_paths)
    end

    it "transforms the EAD files into Solr Documents and indexed them" do
      expect(connection).to have_received(:add).with(solr_documents)
    end
  end
end
