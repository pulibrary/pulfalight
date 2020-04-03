# frozen_string_literal: true

require "rails_helper"

describe "faceted searches", type: :feature, js: true do
  context "with limited facets for date ranges" do
    let(:indexer) do
      Traject::Indexer::NokogiriIndexer.new.tap do |i|
        i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
      end
    end

    let(:fixture_path) do
      Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC221.EAD.xml")
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

    let(:result) do
      indexer.map_record(record)
    end

    before do
      result
      Blacklight.default_index.connection.add(result)
      Blacklight.default_index.connection.commit

      visit "/?search_field=all_fields&q="
    end

    after do
      Blacklight.default_index.connection.delete_by_query("*:*")
      Blacklight.default_index.connection.commit
    end

    it "renders a histogram plot" do
      page.save_screenshot
      expect(page).to have_css("#facet-date_range_sim .chart_js canvas")
    end

    it "renders the number of dated search result items" do
      expect(page).to have_css("#facet-date_range_sim #range_date_range_sim_begin")
      expect(page).to have_css("#facet-date_range_sim #range_date_range_sim_end")
    end

    it "renders the number of undated search result items" do
      expect(page).to have_css("#facet-date_range_sim .missing", text: /Unknown/)
    end
  end
end
