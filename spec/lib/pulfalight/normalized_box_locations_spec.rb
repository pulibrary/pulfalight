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
    { "Firestone Library (hsvm)" => ["Boxes 1-11; 13-17; 221; 323", "Volumes 42-45"],
      "Firestone Library (mss)" => ["Boxes 12; 20-21; 292-293; P-000145"],
      "ReCAP (rcpxm)" => ["Boxes 105; 114; 255; 266"] }
  end

  # Per conversation with Christa Cleeton, include translated location name and code
  # so that end users and staff can both get the info they need.
  it "translates the location codes" do
    expect(normalized_box_locations.locations).to contain_exactly("Firestone Library (hsvm)", "Firestone Library (mss)", "ReCAP (rcpxm)")
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

  context "when there are containers with type: item" do
    let(:box_locations) do
      {
        "st" => { "item" => ["Report No. CS-TR-001-85", "Report No.CS-TR-002-84", "Report No. CS-TR-003-85"] }
      }
    end
    it "can collapse them" do
      expect(described_class.new(box_locations, collapse_items: true).to_h).to eq({
                                                                                    "Engineering Library (st)" => ["3 individual items"]
                                                                                  })
    end

    it "can list them all" do
      expect(normalized_box_locations.to_h).to eq({
                                                    "Engineering Library (st)" => ["Items Report No. CS-TR-001-85; Report No.CS-TR-002-84; Report No. CS-TR-003-85"]
                                                  })
    end
  end

  context "when the item names are actually barcodes" do
    let(:box_locations) do
      # This data was taken from C1449_c00000050
      { "rcpxm" => { "box" => ["4", "10", "10", "10", "10", "10", "10", "10", "10", "10", "10", "4", "10", "10", "10", "11", "11", "11", "4", "4", "11", "4", "11", "11", "11", "11", "11", "11", "11", "11", "11", "4", "11", "11", "4", "11", "11", "11", "11", "11", "11", "11", "11", "11", "11", "4", "11", "11", "11", "11", "11", "4", "4", "4", "4", "11", "11", "11", "4", "11", "11", "11", "12", "12", "11", "11", "12", "12", "12", "12", "12", "12", "4", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "12", "4", "12", "12", "12", "12", "12", "12", "4", "4", "4", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "4", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "13", "5", "5", "5", "5", "5", "5", "5", "5", "5", "13", "13", "13", "5", "5", "5", "5", "5", "5", "5", "5", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "6", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "7", "8", "8", "13", "8", "8", "8", "8", "9", "8", "8", "8"] }, "location_under_review" => { "item" => ["32101047385792", "32101086138714"] } }
    end
    it "doesn't hang forever" do
      expect(normalized_box_locations.to_h).to eq({ "ReCAP (rcpxm)" => ["Boxes 4-13"], "location_under_review" => ["Items 32101047385792; 32101086138714"] })
    end
  end
end
