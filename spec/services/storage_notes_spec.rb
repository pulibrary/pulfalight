# frozen_string_literal: true
require "rails_helper"

RSpec.describe StorageNotes do
  describe ".for" do
    it "returns a combined note if it's two locations" do
      notes = described_class.for(["rcpph", "flm"]).to_a
      expect(notes.first).to eq "This collection is stored at ReCAP and Firestone Library."
    end
    it "returns a Mudd note for mudd/rcpph" do
      notes = described_class.for("mudd").to_a
      notes2 = described_class.for("rcpph").to_a

      expect(notes.length).to eq 1
      expect(notes[0]).to start_with("Mudd Library collections are unavailable until further notice due to a renovation.")
      expect(notes).to eq notes2
    end
    it "returns a ReCAP note for recap locations" do
      ["rcppf", "rcpxg", "rcpxm", "rcpxr", "rcppa"].each do |code|
        notes = described_class.for(code).to_a
        expect(notes.length).to eq 1
        expect(notes.first).to eq "This collection is stored offsite at the ReCAP facility."
      end
    end
    it "returns a firestone note for firestone locations" do
      ["flm", "flmp", "wa", "gax", "ex", "mss", "ex", "flmm", "ctsn", "thx"].each do |code|
        notes = described_class.for(code).to_a
        expect(notes.length).to eq 1
        expect(notes.first).to eq "This collection is stored onsite at Firestone Library."
      end
    end
    it "returns a vault note for vault locations" do
      ["hsvc", "hsvg", "hsvm", "hsvr"].each do |code|
        notes = described_class.for(code).to_a
        expect(notes.length).to eq 1
        expect(notes.first).to eq "This collection is stored in special vault facilities at Firestone Library."
      end
    end
    it "returns an Annex B note" do
      notes = described_class.for("anxb").to_a
      expect(notes.length).to eq 1
      expect(notes.first).to eq "This collection is stored offsite at Annex B (Fine Hall)."
    end
    it "returns an engineering library note" do
      notes = described_class.for("st").to_a
      expect(notes.length).to eq 1
      expect(notes.first).to eq "This collection is stored onsite at the Engineering Library."
    end
    it "returns a plasma physics note" do
      notes = described_class.for("ppl").to_a
      expect(notes.length).to eq 1
      expect(notes.first).to eq "This collection is stored onsite at the Plasma Physics Library."
    end
  end
end
