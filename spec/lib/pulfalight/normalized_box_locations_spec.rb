# frozen_string_literal: true
require "rails_helper"

require_relative "../../../lib/pulfalight/normalized_box_locations"

describe Pulfalight::NormalizedBoxLocations do
  let(:box_locations) do
    {
      "hsvm" => { "box" => ["1", "323", "2", "3", "4", "5", "6", "221", "7", "8", "9", "10", "11", "13", "14", "15", "16", "17"], "volume" => ["42", "43", "44", "45"] },
      "mss" => { "box" => ["12", "20", "21", "P-000145", "292", "293"] },
      "rcpxm" => { "box" => ["255", "266", "114", "105"] }
    }
  end
  let(:normalized_box_locations) { described_class.new(box_locations) }
  let(:human_readable_box_locations) do
    { "This is stored in multiple locations." => [],
      "Firestone Library (hsvm)" => ["Boxes 1-11; 13-17; 221; 323", "Volumes 42-45"],
      "Firestone Library (mss)" => ["Boxes 12; 20-21; 292-293; P-000145"],
      "ReCAP (rcpxm)" => ["Boxes 105; 114; 255; 266"] }
  end

  # Per conversation with Christa Cleeton, include translated location name and code
  # so that end users and staff can both get the info they need.
  it "translates the location codes" do
    expect(normalized_box_locations.locations).to contain_exactly("Firestone Library (hsvm)", "Firestone Library (mss)", "ReCAP (rcpxm)")
  end

  it "groups the boxes into human readable ranges" do
    ranges = { "box" => ["1-11", "13-17", "221", "323"], "volume" => ["42-45"] }
    expect(normalized_box_locations.ranges_for("hsvm")).to eq(ranges)
  end

  it "box ranges include non-numeric box numbers" do
    ranges = { "box" => ["12", "20-21", "292-293", "P-000145"] }
    expect(normalized_box_locations.ranges_for("mss")).to eq(ranges)
  end

  it "generates a human readable summary of the box locations" do
    expect(normalized_box_locations.to_h).to eq human_readable_box_locations
  end

  context "an unrecognized location" do
    let(:box_locations) do
      {
        "review" => { "box" => ["1", "2", "3"] }
      }
    end

    it "records the location without transformation" do
      expect(normalized_box_locations.locations).to contain_exactly("review")
    end
  end

  context "when there is only one location" do
    let(:box_locations) do
      {
        "mudd" => { "box" => ["1", "2", "3"] }
      }
    end
    it "does not say that the collection is in multiple locations." do
      expect(normalized_box_locations.to_h.keys).not_to include("This is stored in multiple locations.")
    end
  end
end
