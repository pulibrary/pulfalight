# frozen_string_literal: true
require "rails_helper"

describe PulfalightHelper, type: :helper do
  describe "#current_year" do
    it "returns the current year" do
      expect(helper.current_year).to eq DateTime.current.year
    end
  end

  context "with a component document" do
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
    let(:xml_documents) do
      nokogiri_reader.to_a
    end
    let(:xml_document) do
      xml_documents.first
    end
    let(:collection_values) do
      indexer.map_record(xml_document)
    end
    let(:component_values) do
      components = collection_values["components"]
      components.first
    end
    let(:component_document) do
      SolrDocument.new(component_values)
    end
    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "aspace", "generated", "publicpolicy", "MC152.processed.EAD.xml")
    end
    let(:facet_params) { instance_double(ActionController::Parameters) }

    before do
      allow(helper).to receive(:document).and_return(component_document)
      without_partial_double_verification do
        allow(helper).to receive(:blacklight_config).and_return(CatalogController.blacklight_config)
      end
      allow(params).to receive(:dig).with("f", "collection_sim").and_return(["Harold B. Hoskins Papers, 1822-1982"])
    end

    describe "#html_presenter" do
      it "accesses the presenter Class used for generating HTML markup" do
        expect(helper.html_presenter).to be_a(ComponentHtmlPresenter)
        expect(helper.html_presenter.collection_notes).to include("<p>Consists of two groups of material collected by Ferree: 1) copies of government reports,")
        expect(helper.html_presenter.collection_notes).to include("</p>")
      end
    end

    describe "#component_notes_formatter" do
      it "generates the HTML markup" do
        expect(helper.component_notes_formatter).to include("<p>Consists of two groups of material collected by Ferree: 1) copies of government reports,")
        expect(helper.component_notes_formatter).to include("</p>")
      end
    end

    describe "#render_search_to_page_header" do
      it "generates the correct collection name" do
        expect(helper.render_search_to_page_header(params)).to include("Harold B. Hoskins Papers, 1822-1982")
      end
    end

    describe "#repository_thumbnail" do
      it "generates the <img> markup for repository thumbnail images" do
        repository_thumbnail = helper.repository_thumbnail
        expect(repository_thumbnail).to include("alt=\"Public Policy Papers\"")
        expect(repository_thumbnail).to include("findingaids.princeton.edu/repositories/publicpolicy.jpg")
      end

      context "when no repository configuration is available" do
        before do
          allow(component_document).to receive(:repository_config).and_return(nil)
        end

        it "generates the default <img> src for repository thumbnail images" do
          expect(helper.repository_thumbnail).to include("/assets/default_repository_thumbnail")
        end
      end
    end
  end

  describe "#hr_separator" do
    it "generates the markup for the Document field values" do
      helper_args = {
        value: [
          "<p class=\"personal-name\">Thorp, Margaret Farrand, 1891-1970</p><p class=\"head\">Biographical / Historical</p>\n<p>\n         William Willard Thorp (1899-1990), literary historian, editor, educator, author, and\n            critic, was born on April 20 in Sydney, New York."
        ]
      }

      markup = helper.hr_separator(helper_args)
      expect(markup).not_to be nil
      expect(markup.to_s).to include("<p>\n         William Willard Thorp (1899-1990)")
    end
  end

  describe "#display_simple_link?" do 
    it "handles bad DAOs" do
      bad_dao = "https://webspace.princeton.edu/users/mudd/Digitization/MC001.01/MC001.01 volume 72.pdf"
      allow(component_document).to receive(:direct_digital_objects).and_return(
        [Arclight::DigitalObject.from_json(
          {
          "href" => bad_dao
          }.to_json
        )]
      )
      allow(component_document).to receive(:figgy_digital_objects).and_return(nil)
      expect { helper.display_simple_link? }.not_to raise_error
    end
  end
end
