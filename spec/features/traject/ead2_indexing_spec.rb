# frozen_string_literal: true
# This spec is modeled on
# https://github.com/projectblacklight/arclight/blob/2336c81e2857f0538dfb57a1297967c29096f9ea/spec/features/traject/ead2_indexing_spec.rb

require "rails_helper"
require Rails.root.join("lib", "pulfalight", "missing_repository_error")

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
    context "when a Repository has been encountered before the collection is indexed" do
      it "retrieves an existing Repository model and indexes this into Solr" do
        expect(result).to include("repository_ssm" => ["Public Policy Papers"])
        expect(result).to include("repository_sim" => ["Public Policy Papers"])
        expect(result["repository_code_ssm"]).to eq ["publicpolicy"]
        expect(result["components"][0]["repository_code_ssm"]).to eq ["publicpolicy"]
      end
    end

    context "when there's not a corresponding Arclight::Repository" do
      let(:settings) do
        {
          repository: "test"
        }
      end

      it "raises a descriptive error" do
        expect { result }.to raise_error(Pulfalight::MissingRepositoryError)
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
    it "indexes a hashed_id_ssi" do
      component = result["components"].first
      expect(component["hashed_id_ssi"]).to eq ["7ecb96f28e7cc0545bab81ba59b12f08"]
    end
    it "indexes ark" do
      expect(result["ark_tsim"]).to eq ["http://arks.princeton.edu/ark:/88435/xp68kk489"]
    end
    it "indexes collection title" do
      component = result["components"].first["components"].first["components"].first
      expect(component["collection_title_tesim"]).to eq ["Walter Dundas Bathurst Papers, 1883-1923"]
    end
  end

  describe "#accessrestrict" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC147.processed.EAD.xml")
    end
    it "inherits down from direct parents" do
      component = find_component(result, "MC147_c07283-24964")
      expect(component["accessrestrict_ssm"]).to eq ["All records in Series 1 are open for research use."]
    end
  end

  context "magic physloc" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
    end

    it "constructs a collection level summary storage note array" do
      summary_message = result["summary_storage_note_ssm"].first
      json = JSON.parse(summary_message)
      expect(json.keys).not_to include("This is stored in multiple locations.")
      expect(json["Firestone Library (scahsvm)"]).to include("Boxes 1; 32; 319")
      expect(json["Firestone Library (scamss)"]).to include("Boxes 12; 83; 330; B-001491")
      expect(json["ReCAP (scarcpxm)"]).to include("Box 232")
    end

    it "constructs component and series level summary storage notes" do
      components = result["components"]
      component = components.first["components"].first
      storage_note = component["summary_storage_note_ssm"].first
      json = JSON.parse(storage_note)
      expect(json.keys).to contain_exactly(
        "Firestone Library (hsvm)",
        "Firestone Library (mss)"
      )
      expect(json["Firestone Library (hsvm)"]).to eq(["Boxes 1; 32"])
      expect(json["Firestone Library (mss)"]).to eq(["Box 12"])
    end

    context "when given a record with sca locations" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC066.EAD.xml")
      end
      it "works" do
        components = result["components"]
        component = components.first
        expect(component["summary_storage_note_ssm"]).to eq ["{\"Mudd Manuscript Library (mudd)\":[\"Box 1\"]}"]
      end
    end

    context "when the collection has components in containers other than boxes" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC154.EAD.xml")
      end
      it "includes them in the summary storage note" do
        component = find_component(result, "AC154_c03425")
        expect(component["summary_storage_note_ssm"]).to eq ["{\"Mudd Manuscript Library (mudd)\":[\"Folders 104-106; Oversize folder 103\"]}"]
      end
    end

    context "when the collection has item containers" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC053.processed.EAD.xml")
      end

      # Items tend to be numerous and have unique individual names, deferring
      # their complete list to the series level component ensures they don't
      # overrun the size of the solr field and also overtake the record display
      it "displays an item count at the collection level" do
        summary_message = result["summary_storage_note_ssm"]
        expect(summary_message).to eq ["{\"Mudd Manuscript Library (mudd)\":[\"1 individual item\"]}"]
      end

      it "displays the full list at the component level" do
        component = find_component(result, "AC053_c846")
        expect(component["summary_storage_note_ssm"]).to eq ["{\"Mudd Manuscript Library (mudd)\":[\"Item 4\"]}"]
      end
    end

    context "when a series has too many items to fit in the solr field" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC297.EAD.xml")
      end

      it "displays an item count instead" do
        component = find_component(result, "AC297_c2")
        expect(component["summary_storage_note_ssm"]).to eq ["{\"ReCAP (rcpph)\":[\"2187 individual items\"]}"]
      end
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
        expect(component["container_information_ssm"]).to eq ["{\"id\":\"a0d983678acfc37567031966489face9\",\"location_code\":\"review\",\"profile\":\"NBox\",\"barcode\":null,\"label\":\"box 101\",\"note\":\"\",\"parent\":\"\",\"type\":\"box\"}"]
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
        expect(child_component_tree["repository_ssm"]).to eq ["Public Policy Papers"]
        expect(child_component_tree["repository_sim"]).to eq ["Public Policy Papers"]
        nested_component_trees = child_component_tree["components"]
        expect(nested_component_trees).not_to be_empty
        nested_component_tree = nested_component_trees.first
        expect(nested_component_tree).to include("id")
        expect(nested_component_tree["id"]).to include("C0251_c0002")
        expect(nested_component_tree["repository_ssm"]).to eq ["Public Policy Papers"]
        expect(nested_component_tree["repository_sim"]).to eq ["Public Policy Papers"]
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

      it "indexes parent_ssi correctly" do
        component = find_component(result, "C0251_c0103")

        expect(component["parent_ssm"]).to eq ["C0251", "C0251_c0101", "C0251_c0102"]
      end
    end

    it "indexes deep children without periods" do
      components = result.as_json["components"]
      component = components.first

      expect(component["parent_ssm"]).to eq ["MC152"]

      child_component = component["components"].last
      expect(child_component["parent_ssm"]).to eq ["MC152", "MC152_c001"]
      expect(child_component["parent_unittitles_ssm"]).to eq ["Barr Ferree collection, 1880s-1920s", "Ferree, James Barr (1862-1924), Presidential messages, Proclamations, etc., 1881-1921"]
      expect(child_component["parent_unnormalized_unittitles_ssm"]).to eq ["Barr Ferree collection", "Ferree, James Barr (1862-1924), Presidential messages, Proclamations, etc."]
    end
  end

  describe "digital objects" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0776.processed.EAD.xml")
    end

    context "when a collection has a direct DAO" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0662.EAD.xml")
      end
      it "indexes direct_digital_objects_ssm" do
        expect(result["direct_digital_objects_ssm"]).not_to be_blank
        expect(result["has_direct_online_content_ssim"]).to eq [true]
      end
    end

    context "when dao is a relative URL path" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "corner_cases", "C1491.relativedao.EAD.xml")
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

    context "YearRange normalizer" do
      it "gives a broad range summary in normalized_date_ssm" do
        expect(result["normalized_date_ssm"]).to eq ["1600s-1900s"]
      end

      it "gives the specific years in date_range_sim" do
        beginning = 1670
        ending = 1900
        expect(result["date_range_sim"]).to eq (beginning..ending).to_a
      end
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

    describe "collection history indexing" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC221.processed.EAD.xml")
      end

      it "indexes acqinfo_teim" do
        expect(result["acqinfo_teim"]).not_to be_empty
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
        combined = JSON.parse(result["userestrict_combined_tsm"].first)
        expect(combined.values.first).to eq result["userestrict_ssm"]
      end

      context "with did searchable notes" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0662.EAD.xml")
        end
        it "indexes extref as links" do
          expect(result["abstract_ssm"]).to eq [
            "Consists primarily of photostatic copies of the letters (1815-1828, 1844-1851) by American banker Daniel Wadsworth Coit to his family in Connecticut--from Lima, Peru, and various cities in Europe, and from the Western United States, Mexico, and San Francisco, California.\n\nThis collection is available online at\n<a href=\"https://dpul.princeton.edu/catalog/gf06g270t\">Digital PUL</a>."
          ]
        end
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

      context "when given a record with mismatched headings/p tags" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
        end
        it "indexes a _combined field for notes" do
          expect(JSON.parse(result["processinfo_combined_tsm"][0]).keys).to eq ["Processing Information"]
        end
      end

      context "when given a record with multiple headings" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1664.processed.EAD.xml")
        end
        it "indexes a _combined field for notes" do
          expect(JSON.parse(result["processinfo_combined_tsm"][0]).keys).to eq ["Processing Information", "Conservation"]
        end
      end

      context "when a collection has a content warning" do
        context "and its component does not" do
          let(:fixture_path) do
            Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "TC040.processed.EAD.xml")
          end
          it "inherits down" do
            component = find_component(result, "TC040_c00002")

            # Ensure it's inheriting from its parent.
            expect(component["scopecontent_combined_tsm"][0]).not_to eq "{}"
            expect(component["scopecontent_ssm"][0]).to include "Many of the photographs"
            expect(component["direct_content_warning_ssm"]).to be_blank
            json = JSON.parse(component["scopecontent_combined_tsm"][0])
            expect(json["Content Warning"]).not_to be_blank
            # Never inherit Scope & Contents
            expect(json["Scope and Contents"]).to be_blank
          end
        end

        context "and its component does" do
          let(:fixture_path) do
            Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1372.processed.EAD.xml")
          end
          it "indexes a direct_content_warning" do
            component = find_component(result, "C1372_c47202-68234")

            expect(component["direct_content_warning_ssm"]).not_to be_blank
          end
        end

        context "when child had a non-warning scopecontent note" do
          let(:fixture_path) do
            Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
          end
          it "still inherits the content warning, keeping its own scopecontent note" do
            component = find_component(result, "WC064_c1")

            # Ensure it's inheriting from its parent.
            expect(component["scopecontent_combined_tsm"][0]).not_to eq "{}"
            expect(component["scopecontent_ssm"][0]).to include "harmful descriptions"
            expect(component["direct_content_warning_ssm"]).to be_blank
            expect(result["direct_content_warning_ssm"]).not_to be_blank
            json = JSON.parse(component["scopecontent_combined_tsm"][0])
            expect(json["Content Warning"]).not_to be_blank
          end
        end
      end

      context "when the collection has a processinfo note" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
        end
        it "does not inherit to the child components" do
          component = find_component(result, "WC064_c1")

          expect(component["processinfo_combined_tsm"]).to be_nil
        end
      end

      context "when a series-level component has a processinfo note" do
        let(:fixture_path) do
          Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1599.processed.EAD.xml")
        end
        it "does not inherit to the child components" do
          # the series with the note is C1599_c380
          # C1599_c1 is its child component
          component = find_component(result, "C1599_c1")

          expect(component["processinfo_combined_tsm"]).to be_nil
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
          expect(result["phystech_ssm"][0]).to start_with "For preservation reasons"
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

    context "when given a sca code" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC066.EAD.xml")
      end
      it "strips the sca" do
        expect(result["physloc_code_ssm"]).to eq(["MUDD"])
        expect(result["physloc_sim"]).to eq(["Mudd Manuscript Library"])
        expect(result["location_code_ssm"]).to eq(["Mudd Manuscript Library"])
        expect(result["components"].first["physloc_code_ssm"]).to eq(["MUDD"])
        expect(result["components"].first["container_information_ssm"]).to eq(["{\"id\":\"76a9adac837d03040a001024b5c7d480\",\"location_code\":\"mudd\",\"profile\":\"NBox\",\"barcode\":\"32101103111116\",\"label\":\"box 1\",\"note\":\"\",\"parent\":\"\",\"type\":\"box\"}"])
      end
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
      it "marks the collection as review because its access-restriction is set to review" do
        expect(result["access_ssi"]).to eq ["review"]
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
    context "for a collection that has review" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1491.processed.EAD.xml")
      end
      it "marks the collection under review" do
        expect(result["access_ssi"]).to eq ["review"]
      end
      it "marks restricted components as restricted" do
        component = find_component(result, "C1491_c1622")

        expect(component["access_ssi"]).to eq ["restricted"]
      end
      it "marks components that are review" do
        component = find_component(result, "C1491_c1")

        expect(component["access_ssi"]).to eq ["review"]
      end
      it "marks components with no accessrestrict of their own as review" do
        component = find_component(result, "C1491_c5011")

        expect(component["access_ssi"]).to eq ["review"]
      end
    end
  end

  context "when there's no collection notes" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "cotsen", "COTSEN4.EAD.xml")
    end
    it "indexes" do
      expect(result).not_to include "collection_notes_ssm"
    end
  end

  context "language_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0879.processed.EAD.xml")
    end

    it "removes punctuation characters from the field values" do
      expect(result).to include("language_ssm")
      expect(result["language_ssm"]).to eq ["Greek, Modern"]
    end

    context "when there are no languages" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC401.processed.EAD.xml")
      end
      it "indexes" do
        expect(result["language_ssm"]).to be_nil
      end
    end

    context "when there are no languages and the component has no language" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1671.EAD.xml")
      end
      it "indexes" do
        expect(result["language_ssm"]).to be_nil
      end
    end

    context "when there are multiple languages" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0776.processed.EAD.xml")
      end

      it "index languages as an array of every language" do
        expect(result["language_ssm"]).to eq ["Geez", "Amharic"]
      end
    end
  end

  describe "ref_ssi" do
    context "for components" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0744.04.processed.EAD.xml")
      end
      it "indexes it with periods" do
        record = find_component(result, "C0744-04_c0120")
        expect(record["ref_ssi"]).to eq ["C0744.04_c0120"]
      end
    end
  end

  describe "unitid_ssm" do
    context "for components" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "univarchives", "AC130.processed.EAD.xml")
      end
      it "indexes unitid and system identifier separately" do
        record = find_component(result, "AC130_c8346")
        expect(record["unitid_ssm"]).to eq nil
        expect(record["system_identifier_ssm"]).to eq ["/repositories/4/archival_objects/1382138"]
      end
    end
  end

  describe "bioghist indexing" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0292.processed.EAD.xml")
    end

    it "indexes it such that it can split out bioghists" do
      expect(result).to include("bioghist_ssm")

      values = result["bioghist_ssm"]
      expect(values.length).to eq(2)

      expect(values.first).to include("Margaret Louise Farrand Thorp (1891-1970), scholar, author, critic, and journalist, was born in East Orange, New Jersey, on December 3, 1891.")
      expect(values.first).to include("<p class=\"personal-name\">Thorp, Margaret Farrand, 1891-1970</p>")

      expect(values.last).to include("William Willard Thorp (1899-1990), literary historian, editor, educator, author, and\n            critic, was born on April 20 in Sydney, New York.")
      expect(values.last).to include("<p class=\"personal-name\">Thorp, Willard, 1899-1990</p>")
    end

    it "indexes it such that it can split out collection_bioghist_ssm" do
      expect(result).to include("bioghist_ssm")
      child_values = result["bioghist_ssm"]
      expect(result).to include("collection_bioghist_ssm")
      values = result["collection_bioghist_ssm"]

      expect(values.length).to eq(2)
      expect(values).to eq(child_values)
    end

    context "when given component bioghists" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0140.processed.EAD.xml")
      end
      it "indexes them" do
        record = find_component(result, "C0140_c80184-00264")

        values = record["bioghist_ssm"]

        expect(values.first).to include("Pierre Samuel Du Pont de Nemours (1739-1817)")
        expect(values.first).to include("<p class=\"personal-name\">Du Pont de Nemours</p>")
      end
    end
  end

  describe "#subject_terms_ssim" do
    context "when given lcsh and non-lcsh subjects" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0140.processed.EAD.xml")
      end
      it "indexes them" do
        record = find_component(result, "C0140_c89292-98183")

        values = record["subject_terms_ssim"]

        expect(values).to include("LGBTQ+ relationships")
        expect(values).to include("French -- California -- History -- 19th century -- Sources")
      end
    end

    context "when given a collection with archaic subject terms" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
      end

      it "replaces them with change the subject values" do
        expect(result["subject_terms_ssim"]).to eq(
          [
            "Indigenous peoples of Central America -- Photographs.",
            "Indigenous peoples of Mexico -- Photographs.",
            "Indigenous peoples of North America -- Photographs.",
            "Indigenous peoples of South America -- Photographs."
          ]
        )
      end
    end

    context "when given a component with archaic subject terms" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
      end

      it "replaces them with change the subject values" do
        record = find_component(result, "WC064_c1")

        values = record["subject_terms_ssim"]

        expect(values).to eq(["Clothing", "Indigenous peoples of North America"])
      end
    end
  end

  describe "#archaic_subject_terms_ssim" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end

    context "when given a collection with archaic subject terms" do
      it "contains all terms replaced by change the subject values" do
        expect(result).to include("archaic_subject_terms_ssim")
        expect(result["archaic_subject_terms_ssim"]).to eq(
          [
            "Indians of Central America -- Photographs.",
            "Indians of Mexico -- Photographs.",
            "Indians of North America -- Photographs.",
            "Indians of South America -- Photographs."
          ]
        )
      end
    end

    context "when given a component with archaic subject terms" do
      it "contains all terms replaced by change the subject values" do
        record = find_component(result, "WC064_c1")

        expect(record).to include("archaic_subject_terms_ssim")
        expect(record["archaic_subject_terms_ssim"]).to eq(["Indians of North America"])
      end
    end
  end

  describe "#access_subjects_ssim" do
    context "when given a collection with archaic subject terms" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
      end

      it "replaces them with change the subject values" do
        expect(result["access_subjects_ssim"]).to eq(
          [
            "Indigenous peoples of Central America -- Photographs.",
            "Indigenous peoples of Mexico -- Photographs.",
            "Indigenous peoples of North America -- Photographs.",
            "Indigenous peoples of South America -- Photographs.",
            "Photographs."
          ]
        )
      end
    end

    context "when given a collection with archaic subject terms and a different term separator" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1539.processed.EAD.xml")
      end

      it "replaces them with change the subject values" do
        expect(result["access_subjects_ssim"]).to eq(
          [
            "Cliff-dwellings -- Arizona -- Photographs.",
            "Hopi Indians.",
            "Indian children--North America--History--19th century--Photographs.",
            "Indigenous peoples of North America--Arizona--1890-1910--Sources.",
            "Indigenous peoples of North America--New Mexico--1890-1910--Sources.",
            "Indigenous peoples of North America--Southwest, New--1890-1910 -- Sources.",
            "Mohave Indians.",
            "Navajo Indians.",
            "Paiute Indians.",
            "Photographs -- 19th century",
            "Photographs -- 20th century.",
            "Pueblo Indians."
          ]
        )
      end
    end

    context "when given a component with archaic subject terms" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
      end

      it "replaces them with change the subject values" do
        record = find_component(result, "WC064_c1")
        values = record["access_subjects_ssim"]

        expect(values).to eq(
          [
            "Clothing",
            "Group portraits",
            "Indigenous peoples of North America",
            "Portrait photographs",
            "Tintypes",
            "Vintage prints"
          ]
        )
      end
    end
  end

  describe "#archaic_subject_terms_ssim" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml")
    end

    context "when given a collection with archaic access subjects" do
      it "contains all terms replaced by change the subject values" do
        expect(result).to include("archaic_access_subjects_ssim")
        expect(result["archaic_access_subjects_ssim"]).to eq(
          [
            "Indians of Central America -- Photographs.",
            "Indians of Mexico -- Photographs.",
            "Indians of North America -- Photographs.",
            "Indians of South America -- Photographs."
          ]
        )
      end
    end

    context "when given a component with archaic access subjects" do
      it "contains all terms replaced by change the subject values" do
        record = find_component(result, "WC064_c1")

        expect(record).to include("archaic_access_subjects_ssim")
        expect(record["archaic_access_subjects_ssim"]).to eq(["Indians of North America"])
      end
    end
  end

  context "when indexing combined fields" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0171.processed.EAD.xml")
    end

    it "indexes them as text" do
      expect(result).to include("scopecontent_combined_tsm")
    end
  end

  describe "#language_ssm" do
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0958.processed.EAD.xml")
    end
    it "overrides the parent language_ssm with the component's if a component has one" do
      record = find_component(result, "C0958_c06413-76702")

      expect(record["language_ssm"]).to eq ["Greek, Modern", "English"]
    end
  end
end
