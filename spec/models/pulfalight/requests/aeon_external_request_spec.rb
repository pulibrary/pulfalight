# frozen_string_literal: true

require "rails_helper"

describe Pulfalight::Requests::AeonExternalRequest do
  let(:repository) { instance_double(Arclight::Repository) }
  let(:document) { instance_double(SolrDocument) }
  let(:presenter) { instance_double(Arclight::ShowPresenter) }
  let(:aeon_external_request) { described_class.new(document, presenter) }

  before do
    allow(document).to receive(:repository).and_return(repository)
    allow(document).to receive(:title).and_return("test title")
    allow(document).to receive(:subtitle).and_return("test subtitle")
    allow(document).to receive(:callnumber).and_return("test callnumber")
    allow(document).to receive(:collection_creator).and_return("test author")
    allow(document).to receive(:normalized_date).and_return("01/01/1970")
    allow(document).to receive(:volume).and_return("test volume")
    allow(document).to receive(:acqinfo).and_return("test acq. info")
    allow(document).to receive(:extent).and_return("test extent")
    allow(document).to receive(:container_titles).and_return([])
    allow(document).to receive(:box_number).and_return(1)
    allow(document).to receive(:physloc_notes).and_return([])
    allow(document).to receive(:physloc_code).and_return("test code")
    allow(document).to receive(:eadid).and_return("C0002")
  end

  describe "#config" do
    let(:config) { aeon_external_request.config }
    it "parses the configuration file" do
      expect(config).to be_a(Hash)
      expect(config).to include("request_mappings")
      expect(config["request_mappings"]).to be_a(Hash)
      expect(config["request_mappings"]).to include("accessor")
      expect(config["request_mappings"]["accessor"]).to be_a(Hash)
      expect(config["request_mappings"]["accessor"]["ItemTitle"]).to eq("title")
      expect(config).to include("request_url")
      expect(config["request_url"]).to eq("https://lib-aeon.princeton.edu/aeon/Aeon.dll")
    end
  end

  describe "#form_mapping" do
    let(:form_mapping) { aeon_external_request.form_mapping }

    it "generates the mappings to form fields from metadata fields and system fields" do
      expect(form_mapping).to be_a(Hash)
      expect(form_mapping).to include(aeon_external_request.static_mappings)

      expect(form_mapping).to include("ItemTitle")
      expect(form_mapping).to include("Location")
      expect(form_mapping).to include("Request")
      expect(form_mapping).to include(:DocumentType)
      expect(form_mapping).to include(:Site)
      expect(form_mapping).to include(:SubmitButton)
    end
  end

  describe "#static_mappings" do
    let(:static_mapping) { aeon_external_request.static_mappings }

    it "generates the mappings to form fields from Aeon system fields" do
      expect(static_mapping).to be_a(Hash)
      expect(static_mapping).to include("AeonForm")
      expect(static_mapping).to include("GroupingIdentifier")
      expect(static_mapping).to include("GroupingOption_CallNumber")
      expect(static_mapping).to include("GroupingOption_ItemDate")
      expect(static_mapping).to include("GroupingOption_ItemInfo1")
      expect(static_mapping).to include("GroupingOption_ItemNumber")
      expect(static_mapping).to include("GroupingOption_ItemVolume")
      expect(static_mapping).to include("GroupingOption_Location")
      expect(static_mapping).to include("GroupingOption_ReferenceNumber")

      expect(static_mapping).to include("Notes")
      expect(static_mapping).to include("RequestType")
      expect(static_mapping).to include("scheduledDate")
      expect(static_mapping).to include(:Request)
    end
  end

  describe "#url_params" do
    let(:url_params) { aeon_external_request.url_params }
    let(:values) do
      {
        "request_mappings" => {
          "url_params" => {
            "param" => "value"
          }
        }
      }
    end

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("config/aeon.yml").and_return(values.to_json)
    end

    it "builds the params for the endpoint URL" do
      expect(url_params).to eq("param=value")
    end
  end

  describe "#url" do
    let(:url) { aeon_external_request.url }

    it "builds the endpoint URL" do
      expect(url).to eq("https://lib-aeon.princeton.edu/aeon/Aeon.dll")
    end
  end
end
