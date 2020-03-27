# frozen_string_literal: true
# This spec is modeled on
# https://github.com/projectblacklight/arclight/blob/2336c81e2857f0538dfb57a1297967c29096f9ea/spec/features/traject/ead2_indexing_spec.rb

require "rails_helper"

describe "EAD 2 traject indexing", type: :feature do
  subject(:result) do
    indexer.map_record(record)
  end

  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new.tap do |i|
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
    Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC221.EAD.xml")
  end

  before do
    ENV["REPOSITORY_ID"] = nil
  end

  after do # ensure we reset these otherwise other tests will fail
    ENV["REPOSITORY_ID"] = nil
  end

  describe "solr fields" do
    it "id" do
      expect(result["id"].first).to eq "MC221"
      component_ids = result["components"].map { |component| component["id"].first }
      expect(component_ids).to include "MC221_c0094"
    end
  end

  describe "digital objects" do
    context "when <dao> is child of the <did> in a <c0x> component" do
      let(:component) { result["components"].find { |c| c["id"] == ["MC221_c0094"] } }

      it "gets the digital objects" do
        expect(component["digital_objects_ssm"]).to eq(
          [
            JSON.generate(
              label: "https://figgy.princeton.edu/concern/scanned_resources/3359153c-82da-4078-ae51-e301f4c5e38b/manifest",
              href: "https://figgy.princeton.edu/concern/scanned_resources/3359153c-82da-4078-ae51-e301f4c5e38b/manifest",
              role: "https://iiif.io/api/presentation/2.1/"
            )
          ]
        )
      end
    end

    context "when <dao> has no role" do
      let(:fixture_path) do
        Rails.root.join("spec", "fixtures", "ead", "mss", "WC064.EAD.xml")
      end
      let(:component) { result["components"].find { |c| c["id"] == ["WC064_c11"] } }

      it "gets the digital objects with role: null" do
        json = JSON.generate(
          label: "http://arks.princeton.edu/ark:/88435/vh53wv96d",
          href: "http://arks.princeton.edu/ark:/88435/vh53wv96d"
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
        "Harold B. Hoskins Papers"
      )
      expect(result["title_teim"]).to eq(
        result["title_ssm"]
      )
    end

    it "asserts that title filing si field is missing" do
      expect(result["title_filing_si"]).to be_nil
    end

    context "YearRange normalizer tests" do
      let(:years) { result["normalized_date_ssm"][0].split("-") }
      let(:beginning) { years[0].to_i }
      let(:ending) { years[1].to_i }

      it "asserts YearRange normalizer works, that normalized_date_ssm contains start and end in date_range_sim field" do
        expect(result["normalized_date_ssm"][0]).to include(
          beginning.to_s,
          ending.to_s
        )
      end

      it "asserts YearRange normalizer works, the # of yrs in date_range_sim array correct, equal to difference between beginning and ending" do
        expect(result["date_range_sim"].length).to equal(
          ending - beginning + 1
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
        ["1822-1982"]
      )
    end

    it "tests normalized title includes title ssm and normalized date" do
      expect(result["normalized_title_ssm"][0]).to include(
        result["title_ssm"][0],
        result["normalized_date_ssm"][0]
      )
    end
  end
end
