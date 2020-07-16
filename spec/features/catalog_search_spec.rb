# frozen_string_literal: true

require "rails_helper"

describe "catalog searches", type: :feature, js: true do
  let(:indexer) do
    Traject::Indexer::NokogiriIndexer.new.tap do |i|
      i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
    end
  end

  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "collection_extents.ead.xml")
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
  end

  after do
    Blacklight.default_index.connection.delete_by_query("*:*")
    Blacklight.default_index.connection.commit
  end

  context "when searching for a specific collection by ID" do
    before do
      visit "/?search_field=all_fields&q=MC148"
    end

    it "renders all collection extents on the collection show page" do
      expect(page).to have_text("278.9 linear feet")
      expect(page).to have_text("632 boxes and 2 oversize folders")
    end
  end

  context "when searching for a specific collection by title" do
    before do
      visit "/?search_field=all_fields&q=david+e.+lilienthal+papers%2C+1900-1981%2C+bulk+1950%2F1981"
    end

    it "renders all collection extents in the collection search results" do
      expect(page).to have_text("278.9 linear feet")
      expect(page).to have_text("632 boxes and 2 oversize folders")
    end
  end
end
