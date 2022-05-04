# frozen_string_literal: true
require "rails_helper"

RSpec.describe AeonRequest do
  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new(indexer_settings).tap do |i|
      i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
    end
  end
  let(:indexer_settings) do
    {
      repository: "publicpolicy"
    }
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
  let(:fixture_file) do
    File.read(fixture_path)
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

  # This is only called from a SolrDocument, so we test it in that context to
  # ensure the SolrDocument creates the correct AeonRequest.
  describe "SolrDocument#aeon_request" do
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
    context "when there's a UnitID" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC362.processed.EAD.xml")
      end
      it "adds it to the ItemVolume" do
        result = indexer.map_record(record)
        component = find_component(component_id: "AC362_c01738", record: result)
        document = SolrDocument.new(component)
        request = document.aeon_request
        request_id = request.form_attributes[:Request]

        expect(request.form_attributes[:"ItemVolume_#{request_id}"]).to eq "Item Number: 1032 Box 1"
      end
    end
    context "when there's a container note" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
      end
      it "adds the note to ItemInfo4" do
        result = indexer.map_record(record)
        component = find_component(component_id: "C1491_c68", record: result)
        document = SolrDocument.new(component)

        request = document.aeon_request
        request_id = request.form_attributes[:Request]
        expect(request.form_attributes[:"Location_#{request_id}"]).to eq "mss"
        expect(request.form_attributes[:"ItemInfo4_#{request_id}"]).to eq "NBox D-zone"
      end
    end

    context "when given a really long access note" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
      end
      it "truncates it" do
        result = indexer.map_record(record)
        component = find_component(component_id: "C1491_c68", record: result)
        document = SolrDocument.new(component)

        request = document.aeon_request
        request_id = request.form_attributes[:Request]
        expect(request.form_attributes[:"ItemInfo1_#{request_id}"].length).to eq 75
      end
    end

    context "when there's one oversize folder and no box" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC053.processed.EAD.xml")
      end
      it "still requests the title and other non-box related data" do
        result = indexer.map_record(record)
        component = find_component(component_id: "AC053_c4917", record: result)
        document = SolrDocument.new(component)

        request = document.aeon_request
        request_id = request.form_attributes[:Request]
        expect(request.form_attributes[:"ItemSubTitle_#{request_id}"]).to eq "Plates and drawings displayed at the World's Columbian Exhibition / Drawing by Logan Coleman *1896"
        expect(request.form_attributes[:"ReferenceNumber_#{request_id}"]).to eq "AC053_c4917"
      end
    end
    context "when there's an oversize folder with notes" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC154.processed.EAD.xml")
      end
      it "adds the notes to ItemInfo4" do
        result = indexer.map_record(record)
        component = find_component(component_id: "AC154_c03425", record: result)
        document = SolrDocument.new(component)

        request = document.aeon_request
        request_id = request.form_attributes[:Request].first
        expect(request.form_attributes[:"ItemInfo4_#{request_id}"]).to eq "Mudd OS folder cabinet 3 drawer 15"
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
    it "returns a grouping option for every field" do
      fixture = Rails.root.join("spec", "fixtures", "C1588.json")
      fixture = JSON.parse(fixture.read)
      component = fixture["components"].first["components"].first["components"].first
      document = SolrDocument.new(component)

      request = document.aeon_request.form_attributes
      request_id = request[:Request]
      fields = request.keys.select do |field|
        field.to_s.include?(request_id)
      end
      fields = fields.map { |field| field.to_s.gsub("_#{request_id}", "").to_sym }

      # These are the fields which stop showing on the call slip if it's
      # multiple folders together. Everything else should.
      non_grouped_fields = [
        :GroupingField,
        :ItemSubTitle,
        :ItemAuthor,
        :ItemInfo2,
        :ItemInfo5
      ]
      fields.each do |field|
        next if non_grouped_fields.include?(field)
        expect(request).to have_key :"GroupingOption_#{field}"
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
      expect(request.attributes[:callnumber]).to eq "C1588_c3"
      expect(request.attributes[:title]).to eq "Diary"
      expect(request.attributes[:containers]).to eq "Box B-001180, Folder 1"
      expect(request.form_attributes[:AeonForm]).to eq "EADRequest"
      expect(request.form_attributes[:RequestType]).to eq "Loan"
      expect(request.form_attributes[:DocumentType]).to eq "Manuscript"
      expect(request.form_attributes[:Location]).to eq "mss"
      expect(request.form_attributes[:GroupingIdentifier]).to eq "GroupingField"
      expect(request.form_attributes[:GroupingOption_ReferenceNumber]).to eq "Concatenate"
      expect(request.form_attributes[:GroupingOption_ItemNumber]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemTitle]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemDate]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_CallNumber]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemVolume]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemInfo1]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_ItemInfo4]).to eq "FirstValue"
      expect(request.form_attributes[:GroupingOption_Location]).to eq "FirstValue"

      # The following attributes are copied from
      # https://findingaids.princeton.edu/collections/C1588/c2
      expect(request.form_attributes[:Request]).not_to be_blank
      request_id = request.form_attributes[:Request]
      # Ensure the box/collection unitid are in as a grouping identifier.
      expect(request.form_attributes[:"GroupingField_#{request_id}"]).to eq "C1588test-box-B-001180"
      expect(request.form_attributes[:"ItemSubTitle_#{request_id}"]).to eq "Diaries / Diary"
      expect(request.form_attributes[:"ItemTitle_#{request_id}"]).to eq "Walter Dundas Bathurst Papers"
      # expect(request.form_attributes[:"ItemAuthor_#{request_id}"]).to eq "Bathurst, Walter Dundas, 1859-1940"
      expect(request.form_attributes[:"ItemDate_#{request_id}"]).to eq "1883 December 11-1884 July 26"
      expect(request.form_attributes[:"ReferenceNumber_#{request_id}"]).to eq "C1588_c3"
      expect(request.form_attributes[:"CallNumber_#{request_id}"]).to eq "C1588test"
      expect(request.form_attributes[:"ItemNumber_#{request_id}"]).to eq "32101080851049"
      expect(request.form_attributes[:"ItemVolume_#{request_id}"]).to eq "Box B-001180"
      expect(request.form_attributes[:"ItemInfo1_#{request_id}"]).to eq "Open for research."
      # This may be wrong. This appears to be the collection extent in
      # findingaids, which would mean this is "1 box"
      expect(request.form_attributes[:"ItemInfo2_#{request_id}"]).to eq "1 folder"
      expect(request.form_attributes[:"ItemInfo3_#{request_id}"]).to eq "Folder 1"
      expect(request.form_attributes[:"Location_#{request_id}"]).to eq "mss"
      expect(request.form_attributes[:"ItemInfo5_#{request_id}"]).to eq "http://localhost:3000/catalog/C1588_c3"
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
      request_id = request.form_attributes[:Request]
      expect(request.form_attributes[:"Site_#{request_id}"]).to eq "RBSC"
    end
  end
  context "when it's a component with rcpph mapping" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC014.processed.EAD.xml")
    end
    it "sets mudd as the site, and leaves ReCAP as the location" do
      result = indexer.map_record(record)
      component = find_component(component_id: "MC014_c03682", record: result)
      document = SolrDocument.new(component)

      request = document.aeon_request
      request_id = request.form_attributes[:Request]
      expect(request.form_attributes[:"Site_#{request_id}"]).to eq "MUDD"
      expect(request.form_attributes[:Location]).to eq "ReCAP"
    end
  end
  context "when there's two boxes for one component" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0187.processed.EAD.xml")
    end
    it "creates two transactions" do
      result = indexer.map_record(record)
      component = result["components"][0]["components"][0]["components"][0]
      document = SolrDocument.new(component)

      request = document.aeon_request
      expect(Array.wrap(request.form_attributes[:Request]).length).to eq 2
      request1 = request.form_attributes[:Request][0]
      request2 = request.form_attributes[:Request][1]

      expect(request.form_attributes[:"Site_#{request1}"]).to eq "RBSC"
      expect(request.form_attributes[:"Site_#{request2}"]).to eq "RBSC"
      expect(request.form_attributes[:"ItemVolume_#{request1}"]).to eq "Box 1"
      expect(request.form_attributes[:"ItemNumber_#{request1}"]).to eq "32101037597877"
      expect(request.form_attributes[:"ItemInfo4_#{request1}"]).to eq "NBox"
      expect(request.form_attributes[:"ItemVolume_#{request2}"]).to eq "Box 2"
      expect(request.form_attributes[:"ItemNumber_#{request2}"]).to eq "32101037597885"
      expect(request.form_attributes[:"ItemInfo4_#{request2}"]).to eq "NBox"
    end
  end
  context "when there's two oversize folders for one component" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC154.processed.EAD.xml")
    end

    it "creates multiple transactions" do
      result = indexer.map_record(record)
      component = find_component(component_id: "AC154_c03425", record: result)
      document = SolrDocument.new(component)

      request = document.aeon_request
      expect(Array.wrap(request.form_attributes[:Request]).length).to eq 4
      request1 = request.form_attributes[:Request][0]
      request2 = request.form_attributes[:Request][1]
      request3 = request.form_attributes[:Request][2]
      request4 = request.form_attributes[:Request][3]

      expect(request.form_attributes[:"Site_#{request1}"]).to eq "MUDD"
      expect(request.form_attributes[:"Site_#{request2}"]).to eq "MUDD"
      expect(request.form_attributes[:"Site_#{request3}"]).to eq "MUDD"
      expect(request.form_attributes[:"Site_#{request4}"]).to eq "MUDD"
      expect(request.form_attributes[:"ItemVolume_#{request1}"]).to eq "Folder Oversize folder 103"
      expect(request.form_attributes[:"ItemVolume_#{request2}"]).to eq "Folder 104"
      expect(request.form_attributes[:"ItemVolume_#{request3}"]).to eq "Folder 105"
      expect(request.form_attributes[:"ItemVolume_#{request4}"]).to eq "Folder 106"
      expect(request.form_attributes[:"ItemVolume_#{request4}"]).to eq "Folder 106"
      expect(request.form_attributes[:"GroupingField_#{request1}"]).to eq "AC154-folder-Oversize-folder-103"
      expect(request.form_attributes[:"GroupingField_#{request2}"]).to eq "AC154-folder-104"
    end
  end
end
