# frozen_string_literal: true
# This spec is modeled on
# https://github.com/projectblacklight/arclight/blob/2336c81e2857f0538dfb57a1297967c29096f9ea/spec/features/traject/ead2_indexing_spec.rb

require "rails_helper"

describe "EAD 2 traject indexing", type: :feature do
  subject(:result) do
    indexer.map_record(record)
  end

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
  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC152.processed.EAD.xml")
  end

  def find_component(result, component_id)
    all_components(result).find { |x| Array.wrap(x["id"]).include?(component_id) }
  end

  def all_components(result)
    [result] + result.fetch("components", []).flat_map { |x| all_components(x) }
  end

  describe "solr fields" do
    it "id" do
      expect(result["id"].first).to eq "MC152"
      component_ids = result["components"].map { |component| component["id"].first }
      expect(component_ids).to include "MC152_c001"
    end
  end

  # Sometimes there are unexpected characters in eadid and componentid that keep
  # the page from rendering as expected
  context "malformed eadid and componentid" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "corner_cases", "MC99999.processed.EAD.xml")
    end
    it "drops anything after a pipe in an eadid" do
      expect(result["id"].first).to eq "MC99999"
      expect(result["ead_ssi"].first).to eq "MC99999"
    end
    it "drops anything after a space in a componentid" do
      expect(result["id"].first).to eq "MC99999"
      component_ids = result["components"].map { |component| component["id"].first }
      expect(component_ids).to include "MC99999_c001"
    end
  end

  describe "repository indexing" do
    context "when a Repository has been before the collection is indexed" do
      it "retrieves an existing Repository model and indexes this into Solr" do
        expect(result).to include("repository_ssm" => ["Public Policy Papers"])
        expect(result).to include("repository_sim" => ["Public Policy Papers"])
        expect(result["repository_code_ssm"]).to eq ["publicpolicy"]
        expect(result["components"][0]["repository_code_ssm"]).to eq ["publicpolicy"]
      end
    end
  end

  describe "ASpace indexing" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1588.EAD.xml")
    end
    it "indexes container_location_codes_ssim" do
      components = result["components"]
      component = components.first["components"].first["components"].first
      expect(component["container_location_codes_ssim"]).to eq ["mss"]
    end
    it "indexes container_information_ssm" do
      components = result["components"]
      component = components.first["components"].first["components"].first
      json = JSON.parse(component["container_information_ssm"][0])
      expect(json["location_code"]).to eq "mss"
      expect(json["profile"]).to eq "NBox"
      expect(json["barcode"]).to eq "32101080851049"
      expect(json["label"]).to eq "box B-001180"
    end
    it "indexes barcodes" do
      components = result["components"]
      component = components.first["components"].first["components"].first
      expect(component["barcodes_ssim"]).to eq ["32101080851049"]
    end
    it "indexes ark" do
      expect(result["ark_tsim"]).to eq ["http://arks.princeton.edu/ark:/88435/xp68kk489"]
    end
    it "indexes collection title" do
      component = result["components"].first["components"].first["components"].first
      expect(component["collection_title_tesim"]).to eq ["Walter Dundas Bathurst Papers, 1883-1923"]
    end
  end

  context "magic physloc" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
    end

    it "constructs a collection level summary storage note" do
      summary_message = result["summary_storage_note_ssm"].first
      expect(summary_message).to match(/This is stored in multiple locations/)
      expect(summary_message).to match(/Firestone Library \(hsvm\): Boxes 1; 32/)
      expect(summary_message).to match(/Firestone Library \(mss\): Boxes 12; 330/)
      expect(summary_message).to match(/ReCAP \(rcpxm\): Box 232/)
    end
    it "constructs component and series level summary storage notes" do
      components = result["components"]
      component = components.first["components"].first
      expect(component["summary_storage_note_ssm"]).to eq ["This is stored in multiple locations.  Firestone Library (hsvm): Boxes 1; 32 Firestone Library (mss): Box 12"]
    end
  end

  context "when given otherlevel text components" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0744.04.processed.EAD.xml")
    end
    it "indexes them as components" do
      components = result["components"]
      component = components.first["components"].first
      expect(component["title_ssm"]).to eq ["Prayer against Shotälay"]
      # Inherit container information from parents.
      expect(component["container_location_codes_ssim"]).to eq ["hsvm"]
      expect(component["container_information_ssm"]).not_to be_blank
      expect(component["barcodes_ssim"]).not_to be_blank
      expect(component["physloc_sim"][0]).not_to be_blank
    end
    context "which don't have container information" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0744.03.processed.EAD.xml")
      end
      it "can index them" do
        components = result["components"]
        expect(components).not_to be_blank
      end
      it "doesn't lose container information from that level" do
        components = result["components"]
        component = components.first["components"].first["components"].first
        expect(component["title_ssm"]).to eq ["Prayer for Driving Away Evil Spirits"]
        expect(component["container_location_codes_ssim"]).to eq ["review"]
        expect(component["container_information_ssm"]).to eq ["{\"location_code\":\"review\",\"profile\":\"NBox\",\"barcode\":null,\"label\":\"box 101\",\"note\":\"\"}"]
        expect(component["barcodes_ssim"]).to be_blank
        expect(component["physloc_sim"]).to eq ["Box 101"]
      end
    end
  end

  context "Oversize folders with cabinet and drawer locations" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC154.processed.EAD.xml")
    end

    it "includes the cabinet and drawer in the physical location" do
      expected_value = "Folder Oversize folder 103 cabinet 3 drawer 15, Folder 104 cabinet 3 drawer 15, Folder 105 cabinet 3 drawer 15, Folder 106 cabinet 3 drawer 15"
      physical_location_with_notes = result["components"].first["components"].first["physloc_sim"]
      expect(physical_location_with_notes).to contain_exactly expected_value
    end
  end

  describe "container indexing" do
    context "when indexing a collection with deeply nested components" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0251.processed.EAD.xml")
      end

      it "indexes the nested components" do
        components = result["components"]
        child_component_trees = components.select { |c| c["components"].present? }
        child_component_tree = child_component_trees.first
        expect(child_component_tree).to include("id")
        expect(child_component_tree["id"]).to include("C0251_c0001")
        nested_component_trees = child_component_tree["components"]
        expect(nested_component_trees).not_to be_empty
        nested_component_tree = nested_component_trees.first
        expect(nested_component_tree).to include("id")
        expect(nested_component_tree["id"]).to include("C0251_c0002")
      end

      it "doesn't index them as top-level components" do
        components = result["components"]
        expect(components.length).to eq 6
        expect(components.group_by { |x| x["id"].first }["C0251_c0002"]).to be_blank
      end

      it "doesn't leave empty arrays around" do
        component = result.as_json["components"].first

        expect(component["scopecontent_ssm"]).not_to be_empty
        expect(component["scopecontent_ssm"].length).to eq(1)
        expect(component["scopecontent_ssm"].first).not_to be_empty
      end
    end

    it "indexes deep children without periods" do
      components = result.as_json["components"]
      component = components.first

      expect(component["parent_ssm"]).to eq ["MC152"]

      child_component = component["components"].last
      expect(child_component["parent_ssm"]).to eq ["MC152", "MC152_c001"]
      expect(child_component["parent_unittitles_ssm"]).to eq ["Barr Ferree collection, 1880-1929", "Ferree, James Barr (1862-1924), Presidential messages, Proclamations, etc., 1881-1921"]
      expect(child_component["parent_unnormalized_unittitles_ssm"]).to eq ["Barr Ferree collection", "Ferree, James Barr (1862-1924), Presidential messages, Proclamations, etc."]
    end
  end

  describe "digital objects" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0776.processed.EAD.xml")
    end

    context "when dao is a relative URL path" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
      end
      it "doesn't index it" do
        expect(result["has_online_content_ssim"]).to eq [false]
        expect(result["digital_objects_ssm"]).to be_blank
        component = result["components"][0]
        expect(component["has_online_content_ssim"]).to eq [false]
        leaf_component = component["components"][0]["components"][0]["components"][0]
        expect(leaf_component["has_direct_online_content_ssim"]).to eq [false]
        expect(component["digital_objects_ssm"]).to be_blank
        expect(leaf_component["direct_digital_objects_ssm"]).to be_blank
      end
    end

    context "when <dao> is child of the <did> in a <c0x> component" do
      let(:components) { result["components"] }
      let(:dao_components) { components.select { |c| c["digital_objects_ssm"] } }
      let(:component) { dao_components.last }

      it "gets the digital objects" do
        expect(component["digital_objects_ssm"]).to eq(
          [
            JSON.generate(
              label: "View digital content",
              href: "https://figgy.princeton.edu/concern/scanned_resources/919b6dfa-db00-437c-a49d-0b76eb4358d1/manifest",
              role: "https://iiif.io/api/presentation/2.1/"
            )
          ]
        )
        expect(component["direct_digital_objects_ssm"]).to eq(
          [
            JSON.generate(
              label: "View digital content",
              href: "https://figgy.princeton.edu/concern/scanned_resources/919b6dfa-db00-437c-a49d-0b76eb4358d1/manifest",
              role: "https://iiif.io/api/presentation/2.1/"
            )
          ]
        )
        expect(component["has_online_content_ssim"]).to eq [true]
        expect(component["has_direct_online_content_ssim"]).to eq [true]
      end
    end

    context "when <dao> has no role" do
      let(:settings) do
        {
          repository: "mss"
        }
      end
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC085.processed.EAD.xml")
      end
      let(:component) { result["components"].find { |c| c["id"] == ["MC085_c01084"] }["components"][0]["components"][0] }

      it "gets the digital objects with role: null" do
        json = JSON.generate(
          label: "View digital content",
          href: "https://figgy.princeton.edu/collections/6ff2c854-f102-4a5e-861d-276179a3a5f0/manifest"
        ).slice(0..-2) + ",\"role\":null}"
        expect(component["digital_objects_ssm"]).to eq(
          [
            json
          ]
        )
      end
    end

    it "gets the title tesim" do
      expect(result["title_teim"]).to include(
        "Princeton Ethiopic Manuscripts"
      )
      expect(result["title_teim"]).to eq(
        result["title_ssm"]
      )
    end

    it "asserts that title filing si field is missing" do
      expect(result["title_filing_si"]).to be_nil
    end

    context "YearRange normalizer tests" do
      let(:dates) { result["normalized_date_ssm"] }
      let(:date_range) { result["date_range_sim"] }
      let(:date) { dates.first }
      let(:years) { date.split("-") }
      let(:beginning) { years.first.to_i }
      let(:ending) { years.last.to_i }

      it "asserts YearRange normalizer works, that normalized_date_ssm contains start and end in date_range_sim field" do
        expect(years).to include(
          beginning.to_s,
          ending.to_s
        )
      end

      it "asserts YearRange normalizer works, the # of yrs in date_range_sim array correct, equal to difference between beginning and ending" do
        # <unitdate normal="1670/1900" type="inclusive">1600s-1900s</unitdate>

        expect(date_range.length).to equal(
          ending - 1670 + 1
        )
      end

      it "asserts YearRange normalizer works, date_range_sim contains a random year between begin and end" do
        expect(result["date_range_sim"]).to include(
          rand(beginning..ending)
        )
      end
    end

    it "gets the normalized date" do
      expect(result["normalized_date_ssm"]).to eq(
        ["1670-1900"]
      )
    end

    it "tests normalized title includes title ssm and normalized date" do
      normal_titles = result["normalized_title_ssm"]
      titles = result["title_ssm"]
      normal_dates = result["normalized_date_ssm"]

      expect(normal_titles.first).to include(
        titles.first,
        normal_dates.first
      )
    end

    context "a collection with 'mostly' dates" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0062.processed.EAD.xml")
      end

      it "does not repeat the dates, and formats the mostly" do
        expect(result["normalized_title_ssm"]).to contain_exactly "Booth Tarkington Papers, 1812-1956 (mostly 1899-1946)"
      end
    end

    describe "collection notes indexing" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC221.processed.EAD.xml")
      end

      it "indexes extref as links" do
        expect(result["userestrict_ssm"]).to eq [
          "Single photocopies may be made for research purposes. For quotations that are fair use as defined under <a href=\"http://copyright.princeton.edu/basics/fair-use\">U. S. Copyright Law</a>, no permission to cite or publish is required. For those few instances beyond fair use, researchers are responsible for determining who may hold the copyright and obtaining approval from them. Researchers do not need anything further from the Mudd Library to move forward with their use."
        ]
      end

      context "when given a staff-only physloc code" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
        end
        it "doesn't index" do
          component = find_component(result, "C1491_c5621")
          expect(component["physloc_ssm"]).to eq ["Box 330 D-zone, Folder 5-6"]
        end
      end

      it "indexes all note fields from the <archdesc> child elements for the collection" do
        expect(result).to include("collection_notes_ssm")
        expect(result["collection_notes_ssm"]).not_to be_empty
        notes = result["collection_notes_ssm"].join
        expect(notes).to include("The Harold B. Hoskins Papers consist of correspondence, diaries, notes")
        expect(notes).to include("The collection is open for research use.")
        expect(notes).to include("Single photocopies may be made for research purposes. For quotations that are fair use as defined under")
        expect(notes).to include("Gifted to the American Heritage Center at the University of Wyoming by Grania H.")
        expect(notes).to include("Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in")
        expect(notes).to include("boxes of books were separated during processing in 2007. No materials were")
        expect(notes).to include("A preliminary inventory list, MARC record and collection-level description were")

        expect(result["collection_notes_ssm"]).not_to include("The collection is open for research use.\n            \n")
      end

      context "when given a collection with arrangement" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0776.processed.EAD.xml")
        end
        it "indexes the requested notes" do
          expect(result["arrangement_ssm"]).to eq ["Arranged in manuscript number order, by accession. Numbers 29 and 67-71 are unassigned."]
        end
      end
      context "when given a collection with a phystech note" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC148.processed.EAD.xml")
        end
        it "indexes the requested notes" do
          expect(result["phystech_ssm"]).to eq ["Access to audiovisual material in this collection follows the Mudd Manuscript Library <a href=\"http://rbsc.princeton.edu/policies/mudd-library-imaging-guidelines-and-price-list#Audio%20visual\">policy for preservation and access to audiovisual materials</a>."]
          expect(result["components"][0]["phystech_ssm"]).to eq result["phystech_ssm"]
        end
      end
      context "when given a collection with an otherfindaid" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC001.02.06.processed.EAD.xml")
        end
        it "indexes otherfindaid note" do
          expect(result["otherfindaid_ssm"]).to eq ["This finding aid describes a portion of the American Civil Liberties Union Records held at the Seeley G. Mudd Manuscript Library. For an overview of the entire collection, instructions on searching the collection and requesting materials, and other information, please see the <a href=\"http://libguides.princeton.edu/mudd_aclu\">Guide to the American Civil Liberties Union Records</a>."]
        end
      end
      it "indexes the requested notes" do
        # Description, do not propagate.
        expect(result["scopecontent_ssm"]).to eq ["The Harold B. Hoskins Papers consist of correspondence, diaries, notes, photographs, publications, maps, and professional files that document Hoskins' personal and professional activities, as well as the Hoskins family. See individual series descriptions for more specific information on each series."]
        # Access restriction, propagate
        expect(result["accessrestrict_ssm"]).to eq ["The collection is open for research use."]
        expect(result["components"][0]["accessrestrict_ssm"]).to eq result["accessrestrict_ssm"]
        # Use restriction, propagate
        expect(result["userestrict_ssm"]).to eq ["Single photocopies may be made for research purposes. For quotations that are fair use as defined under <a href=\"http://copyright.princeton.edu/basics/fair-use\">U. S. Copyright Law</a>, no permission to cite or publish is required. For those few instances beyond fair use, researchers are responsible for determining who may hold the copyright and obtaining approval from them. Researchers do not need anything further from the Mudd Library to move forward with their use."]
        expect(result["components"][0]["userestrict_ssm"]).to eq result["userestrict_ssm"]
        # Acquisition Info
        expect(result["acqinfo_ssm"]).to eq [
          "Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in November 2007 (accession number ML.2007.037). Grania Ackley donated eight rolls of 16mm safety film and a file of correspondence in May 2012 (accession number ML.2012.020). The materials that comprise Series 3 were donated by John and Binti Ackley in 2014 (accession number ML.2014.029)."
        ]
        # Accruals - unable to find
      end

      context "when names and descriptions contain ampersands" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0140.processed.EAD.xml")
        end
        it "escapes them before indexing" do
          component = find_component(result, "C0140_c83445-31032")
          expect(component["scopecontent_ssm"].first).to match(/J.P Ball & Son/)
        end
      end

      it "indexes all note fields from the <archdesc> child elements for the child components" do
        components = result["components"]
        component = components.first

        expect(component).to include("collection_notes_ssm")
        expect(component["collection_notes_ssm"]).not_to be_empty
        notes = component["collection_notes_ssm"].join
        expect(notes).to include("The Harold B. Hoskins Papers consist of correspondence, diaries, notes")
        expect(notes).to include("The collection is open for research use.")
        expect(notes).to include("Single photocopies may be made for research purposes. For quotations that are fair use as defined under")
        expect(notes).to include("Gifted to the American Heritage Center at the University of Wyoming by Grania H.")
        expect(notes).to include("Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in")
        expect(notes).to include("boxes of books were separated during processing in 2007. No materials were")
        expect(notes).to include("A preliminary inventory list, MARC record and collection-level description were")

        nested_components = components.flat_map { |c| c["components"] }
        nested_component = nested_components.first

        expect(nested_component).to include("collection_notes_ssm")
        expect(nested_component["collection_notes_ssm"]).not_to be_empty
        notes = nested_component["collection_notes_ssm"].join
        expect(notes).to include("The Harold B. Hoskins Papers consist of correspondence, diaries, notes")
        expect(notes).to include("The collection is open for research use.")
        expect(notes).to include("Single photocopies may be made for research purposes. For quotations that are fair use as defined under")
        expect(notes).to include("Gifted to the American Heritage Center at the University of Wyoming by Grania H.")
        expect(notes).to include("Scott Rodman approved the gifting to Mudd on behalf of the Hoskins family in")
        expect(notes).to include("boxes of books were separated during processing in 2007. No materials were")
        expect(notes).to include("A preliminary inventory list, MARC record and collection-level description were")
      end
    end
  end

  describe "generating citations" do
    it "generates a citation for any given collection" do
      expect(result).to include("prefercite_ssm")
      expect(result["prefercite_ssm"]).to include("Barr Ferree collection; Public Policy Papers, Department of Special Collections, Princeton University Library")
      expect(result).to include("prefercite_teim")
      expect(result["prefercite_teim"]).to include("Barr Ferree collection; Public Policy Papers, Department of Special Collections, Princeton University Library")
    end

    it "generates a citation for any given component" do
      expect(result).to include("components")
      components = result["components"]
      expect(components).not_to be_empty
      component = components.first

      expect(component).to include("prefercite_ssm")
      expect(component["prefercite_ssm"]).to include("Ferree, James Barr (1862-1924), Presidential messages, Proclamations, etc.; Barr Ferree collection, MC152, Public Policy Papers, Department of Special Collections, Princeton University Library")
      expect(component).to include("prefercite_teim")
      expect(component["prefercite_teim"]).to include("Ferree, James Barr (1862-1924), Presidential messages, Proclamations, etc.; Barr Ferree collection, MC152, Public Policy Papers, Department of Special Collections, Princeton University Library")
    end
  end

  describe "indexing collection component extent values" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC148.processed.EAD.xml")
    end

    it "indexes all extent elements" do
      expect(result).to include("components")
      components = result["components"]
      expect(components.length).to eq(2)
      expect(components.first).to include("components")
      child_components = components.first["components"]
      expect(child_components.length).to eq(2)
      expect(child_components.first).to include("id" => ["MC148_c00002"])
      expect(child_components.last).to include("id" => ["MC148_c00018"])

      expect(result).to include("extent_ssm")
      expect(result["extent_ssm"].length).to eq(2)
      expect(result["extent_ssm"]).to include("4 items")
      expect(result["extent_ssm"]).to include("632 boxes")
    end
  end

  context "indexing collection component physdesc/physfacet" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
    end
    it "indexes physfacet" do
      component = find_component(result, "C1491_c5239")
      expect(component["physfacet_ssm"]).to eq ["10 audio cassettes"]
      expect(component["physfacet_teim"]).to eq ["10 audio cassettes"]
    end
  end

  describe "#physloc_code_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end

    it "resolves and indexes the physical location code" do
      expect(result).to include("physloc_code_ssm")
      expect(result["physloc_code_ssm"]).to eq(["RBSC"])
    end

    it "resolves and indexes the physical location code in child components" do
      expect(result).to include("components")
      components = result["components"]
      expect(components).not_to be_empty
      expect(components.first).to include("physloc_code_ssm")
      expect(components.first["physloc_code_ssm"]).to eq(["RBSC"])
    end
  end

  describe "#location_code_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end

    it "resolves and indexes the location code" do
      expect(result).to include("location_code_ssm")
      expect(result["location_code_ssm"]).to eq(["Firestone Library"])
    end
  end

  describe "#location_note_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end

    it "indexes the location note" do
      result
      expect(result).to include("location_note_ssm")
      expect(result["location_note_ssm"]).to eq(["Boxes H4 and H5 (Lummis glass plate negatives) and H6 (California Gold Rush daguerreotype) are stored in special vault facilities."])
    end
  end

  describe "#volume_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC152.processed.EAD.xml")
    end

    # I can't find any data from ASpace that has "vol" in the extent anymore. We
    # don't seem to use this field.
    xit "indexes extent values encoding volume numbers" do
      expect(result).to include("components")
      components = result["components"].select { |c| c.key?("volume_ssm") }
      expect(components).not_to be_empty
    end
  end

  describe "#physdesc_number_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "C0776.EAD.xml")
    end

    # I don't think we need this anymore, and this isn't how this component is
    # indexed in ASpace.
    xit "indexes physical description values encoding material numbers" do
      expect(result).to include("components")
      components = result["components"].select { |c| c.key?("physdesc_number_ssm") }
      expect(components).not_to be_empty

      expect(components.first).to include("physdesc_number_ssm")
      expect(components.first["physdesc_number_ssm"]).to eq(["1"])
    end
  end

  describe "#names_ssim" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end

    it "does not include staff names" do
      expect(result["names_ssim"]).not_to include "Heather Shannon"
    end
  end

  describe "creator_ssim" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1165.processed.EAD.xml")
    end
    it "separates creators and collectors" do
      expect(result["creators_ssim"]).to eq ["Henry, Patrick, 1736-1799", "Princeton University. Library. Special Collections"]
      expect(result["collectors_ssim"]).to eq ["Princeton University. Library. Special Collections"]
    end
  end

  describe "names_coll_ssim" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0140.processed.EAD.xml")
    end
    it "indexes names" do
      component = find_component(result, "C0140_c29843-01832")
      expect(component["names_ssim"]).to eq ["United States. Navy. Mediterranean Squadron", "Gallatin, Albert, 1761-1849"]
    end
  end

  describe "access_ssi" do
    context "for records with no restrictions" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1629.EAD.xml")
      end
      it "is open" do
        component = find_component(result, "C1629_c1")
        expect(component["access_ssi"]).to eq ["open"]
      end
    end
    context "for components whose series is restricted" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "corner_cases", "AC136.noaccess.EAD.xml")
      end
      it "is restricted" do
        component = find_component(result, "AC136_c2889")
        expect(component["access_ssi"]).to eq ["restricted"]
      end
      it "marks the collection as some-restricted" do
        expect(result["access_ssi"]).to eq ["some-restricted"]
      end
    end
    context "for a collection which is entirely restricted" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0187.processed.EAD.xml")
      end
      it "marks the parent and all children restricted" do
        expect(result["access_ssi"]).to eq ["restricted"]
      end
    end
  end

  describe "language_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0879.processed.EAD.xml")
    end

    it "removes punctuation characters from the field values" do
      expect(result).to include("language_ssm")
      expect(result["language_ssm"]).to eq ["Greek, Modern"]
    end
  end
end
