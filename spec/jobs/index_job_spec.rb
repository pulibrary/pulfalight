# frozen_string_literal: true
require "rails_helper"

describe IndexJob do
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
      "unitid_ssm" => ["WC127"]
    }
  end
  let(:solr_documents) do
    [
      solr_document
    ]
  end
  let(:indexer) { instance_double(Traject::Indexer::NokogiriIndexer) }

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
