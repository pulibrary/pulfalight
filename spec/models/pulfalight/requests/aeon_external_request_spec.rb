# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pulfalight::Requests::AeonExternalRequest do
  subject(:aeon_external_request) do
    described_class.new(document, presenter)
  end
  let(:view_context) { ActionView::Base.new }
  let(:config) { Blacklight::Configuration.new }

  let(:settings) do
    {
      repository: "publicpolicy"
    }
  end
  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new(settings).tap do |i|
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
  let(:solr_values) do
    indexer.map_record(record)
  end
  let(:document) { SolrDocument.new(solr_values) }
  let(:presenter) { Arclight::ShowPresenter.new(document, view_context, config) }
  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC152.processed.EAD.xml")
  end

  describe "#form_mapping" do
    let(:form_mapping) do
      aeon_external_request.form_mapping
    end

    it "generates the <form> fields for a Pulfalight Document" do
      expect(form_mapping).to include("AeonForm" => "EADRequest")
      expect(form_mapping).to include("GroupingIdentifier" => "ItemVolume")
      expect(form_mapping).to include("GroupingOption_CallNumber" => "FirstValue")
      expect(form_mapping).to include("GroupingOption_ItemDate" => "FirstValue")
      expect(form_mapping).to include("GroupingOption_ItemInfo1" => "FirstValue")
      expect(form_mapping).to include("GroupingOption_ItemNumber" => "Concatenate")
      expect(form_mapping).to include("GroupingOption_ItemVolume" => "FirstValue")
      expect(form_mapping).to include("GroupingOption_Location" => "FirstValue")
      expect(form_mapping).to include("GroupingOption_ReferenceNumber" => "Concatenate")

      expect(form_mapping).to include("ItemTitle" => ["Barr Ferree collection"])
      expect(form_mapping).to include("Location" => "Mudd Manuscript Library")
      expect(form_mapping).to include("Notes" => "")
      expect(form_mapping).to include("RequestType" => "Loan")
      expect(form_mapping).to include("scheduledDate" => "")

      expect(form_mapping).to include(DocumentType: "Manuscript")
      expect(form_mapping).to include(Site: nil)
      expect(form_mapping).to include(SubmitButton: "Submit Request")
    end
  end

  describe "#url" do
    let(:url) do
      aeon_external_request.url
    end

    context "with URL parameters specified in the configuration file" do
      let(:config_file_path) do
        Rails.root.join("spec", "fixtures", "config", "aeon_request_mappings.yml")
      end

      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with("config/aeon.yml").and_return(File.read(config_file_path))
      end

      it "appends the URL parameters to the Aeon <form> action URL" do
        expect(url).to eq("https://example.com/aeon.dll?token=2d94befc-9a97-48b7-b724-7eb262c83055")
      end
    end
    context "with a missing URL in the configuration" do
      let(:config_file_path) do
        Rails.root.join("spec", "fixtures", "config", "aeon_invalid.yml")
      end

      let(:config_file_path) do
        Rails.root.join("spec", "fixtures", "config", "aeon_invalid.yml")
      end

      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with("config/aeon.yml").and_return(File.read(config_file_path))
        allow(Rails.logger).to receive(:error)
      end

      it "raises an error" do
        expect { url }.to raise_error(KeyError)
        expect(Rails.logger).to have_received(:error).with("No request service URL is configured for Aeon in config/aeon.yml")
      end
    end
  end
end
