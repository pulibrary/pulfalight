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

  describe "#storage_notes" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1387.processed.EAD.xml")
    end
    let(:values) do
      indexer.map_record(record)
    end
    let(:document) { SolrDocument.new(values) }
    it "can create combined storage notes if it's in two locations" do
      expect(document.storage_notes).to eq [
        "This collection is stored at ReCAP and Firestone Library.",
        "This collection is stored partially (Boxes 1-2, 5-6) on-site at Firestone Library and partially off-site (Boxes 3-4) at ReCAP."
      ]
    end
  end

  describe "#component_storage_notes" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1387.processed.EAD.xml")
    end
    let(:values) do
      indexer.map_record(record)
    end
    let(:component) { values["components"].first }
    let(:document) { SolrDocument.new(component) }
    it "can create combined storage notes if it's in two locations" do
      expect(document.component_storage_notes).to eq [
        "This collection is stored at ReCAP and Firestone Library.",
        "This collection is stored partially (Boxes 1-2, 5-6) on-site at Firestone Library and partially off-site (Boxes 3-4) at ReCAP."
      ]
    end
  end

  describe "#aeon_request" do
    context "#requestable?" do
      it "returns false if it's not a leaf node" do
        fixture = Rails.root.join("spec", "fixtures", "C1588.json")
        fixture = JSON.parse(fixture.read)
        component = fixture["components"].first["components"].first
        document = SolrDocument.new(component)

        request = document.aeon_request

        expect(request).not_to be_requestable
      end
      it "returns false if there's no location code" do
        fixture = Rails.root.join("spec", "fixtures", "C1588.json")
        fixture = JSON.parse(fixture.read)
        component = fixture["components"].first["components"].first
        component["components"] = []
        document = SolrDocument.new(component)

        request = document.aeon_request

        expect(request).not_to be_requestable
      end
    end
    context "when given a ReCAP location" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1408.processed.EAD.xml")
      end
      let(:values) do
        indexer.map_record(record)["components"][0]["components"][0]["components"][0]
      end
      let(:document) { SolrDocument.new(values) }
      it "returns ReCAP as the location" do
        request = document.aeon_request
        expect(request.form_attributes[:Location]).to eq "ReCAP"
        request_id = request.form_attributes[:Request]
        expect(request.form_attributes[:"Location_#{request_id}"]).to eq "ReCAP"
      end
    end
    let(:indexer) do
      Traject::Indexer::NokogiriIndexer.new(indexer_settings).tap do |i|
        i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
      end
    end
    context "when there's a container profile" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1588.EAD.xml")
      end
      it "adds the container profile as ItemInfo4" do
        result = indexer.map_record(record)
        component = result["components"].first["components"].first["components"].first
        document = SolrDocument.new(component)

        request = document.aeon_request
        request_id = request.form_attributes[:Request]
        expect(request.form_attributes[:"Location_#{request_id}"]).to eq "mss"
        expect(request.form_attributes[:"ItemInfo4_#{request_id}"]).to eq "NBox"
      end
    end
    context "when it's an item component" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0744.04.processed.EAD.xml")
      end
      it "is requestable as a child of the parent component" do
        result = indexer.map_record(record)
        component = result["components"].first["components"].first
        document = SolrDocument.new(component)

        request = document.aeon_request
        request_id = request.form_attributes[:Request]
        expect(request.form_attributes[:"Location_#{request_id}"]).to eq "hsvm"
        expect(request.form_attributes[:"ItemInfo4_#{request_id}"]).to eq "NBox"
        expect(request.form_attributes[:"ItemVolume_#{request_id}"]).to eq "Box 1"
        expect(request.form_attributes[:"ItemNumber_#{request_id}"]).to eq "32101038557656"
        # There's no folder for this item.
        expect(request.form_attributes[:"ItemInfo3_#{request_id}"]).to be_nil
      end
    end
    it "returns an object with all the necessary attributes" do
      # The following fixture is generated from a fixture exported from our
      # local system. It's created via `rake
      # pulfalight:fixtures:regenerate_json.
      # TODO: Migrate to fixture generated from aspace. Right now creator isn't
      #   in that EAD yet.
      fixture = Rails.root.join("spec", "fixtures", "C1588.json")
      fixture = JSON.parse(fixture.read)
      component = fixture["components"].first["components"].first["components"].first
      document = SolrDocument.new(component)

      request = document.aeon_request
      expect(request.attributes[:callnumber]).to eq "aspace_C1588_c3"
      expect(request.attributes[:title]).to eq "Diary"
      expect(request.attributes[:containers]).to eq "Box B-001180, Folder 1"
      expect(request.form_attributes[:AeonForm]).to eq "EADRequest"
      expect(request.form_attributes[:RequestType]).to eq "Loan"
      expect(request.form_attributes[:DocumentType]).to eq "Manuscript"
      expect(request.form_attributes[:Site]).to eq "RBSC"
      expect(request.form_attributes[:Location]).to eq "mss"
      expect(request.form_attributes[:ItemTitle]).to eq "Diary"
      expect(request.form_attributes[:GroupingIdentifier]).to eq "GroupingField"
      expect(request.form_attributes[:GroupingOption_ReferenceNumber]).to eq "Concatenate"
      expect(request.form_attributes[:GroupingOption_ItemNumber]).to eq "Concatenate"
      expect(request.form_attributes[:GroupingOption_ItemDate]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_CallNumber]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemVolume]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemInfo1]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_Location]).to eq "FirstValue"

      # The following attributes are copied from
      # https://findingaids.princeton.edu/collections/C1588/c2
      expect(request.form_attributes[:Request]).not_to be_blank
      request_id = request.form_attributes[:Request]
      # Ensure the box/collection unitid are in as a grouping identifier.
      expect(request.form_attributes[:"GroupingField_#{request_id}"]).to eq "C1588test-Box B-001180"
      expect(request.form_attributes[:"ItemSubTitle_#{request_id}"]).to eq "Diaries / Diary"
      expect(request.form_attributes[:"ItemTitle_#{request_id}"]).to eq "Walter Dundas Bathurst Papers"
      expect(request.form_attributes[:"ItemAuthor_#{request_id}"]).to eq "Bathurst, Walter Dundas, 1859-1940"
      expect(request.form_attributes[:"ItemDate_#{request_id}"]).to eq "1883 December 11-1884 July 26"
      expect(request.form_attributes[:"ReferenceNumber_#{request_id}"]).to eq "aspace_C1588_c3"
      expect(request.form_attributes[:"CallNumber_#{request_id}"]).to eq "C1588test"
      expect(request.form_attributes[:"ItemNumber_#{request_id}"]).to eq "32101080851049"
      expect(request.form_attributes[:"ItemVolume_#{request_id}"]).to eq "Box B-001180"
      expect(request.form_attributes[:"ItemInfo1_#{request_id}"]).to eq "Open for research."
      # This may be wrong. This appears to be the collection extent in
      # findingaids, which would mean this is "1 box"
      expect(request.form_attributes[:"ItemInfo2_#{request_id}"]).to eq "1 folder"
      expect(request.form_attributes[:"ItemInfo3_#{request_id}"]).to eq "Folder 1"
      expect(request.form_attributes[:"Location_#{request_id}"]).to eq "mss"
      expect(request.form_attributes[:"ItemInfo5_#{request_id}"]).to eq "http://localhost:3000/catalog/aspace_C1588_c3"
      expect(request.form_attributes[:SubmitButton]).to eq "Submit Request"
    end
  end
  context "when it's a component with no physloc mapping (hsvm)" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0187.processed.EAD.xml")
    end
    it "defaults to RBSC as the Site" do
      result = indexer.map_record(record)
      component = result["components"].first
      document = SolrDocument.new(component)

      request = document.aeon_request
      expect(request.form_attributes[:Site]).to eq "RBSC"
    end
  end
end
