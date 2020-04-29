# frozen_string_literal: true

require "rails_helper"
require "arclight/traject/nokogiri_namespaceless_reader"

describe Ead2IdMinterService do
  subject(:minter_service) { described_class.new(node: node) }

  let(:fixture_path) do
    Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC221_pruned.EAD.xml")
  end
  let(:fixture_file) do
    File.read(fixture_path)
  end
  let(:nokogiri_reader) do
    Arclight::Traject::NokogiriNamespacelessReader.new(fixture_file.to_s, {})
  end
  let(:records) do
    nokogiri_reader.to_a
  end
  let(:record) do
    records.first
  end
  let(:xpath) do
    "/ead/archdesc/dsc[@type='combined']/c[@level != 'otherlevel']"
  end
  let(:node) do
    record.at_xpath(xpath)
  end

  describe "#mint" do
    it "generates a new ID for the XML element" do
      minted = minter_service.mint
      expect(minted).not_to be_empty
      expect(minted).to include("al_")
      expect(minted.length).to eq(43)
    end
  end
end
