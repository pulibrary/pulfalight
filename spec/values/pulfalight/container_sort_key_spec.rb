# frozen_string_literal: true
require "rails_helper"

RSpec.describe Pulfalight::ContainerSortKey do
  describe ".build" do
    it "pads number strings so they sort in numeric order" do
      expect(described_class.build("2")).to be < described_class.build("10")
    end

    it "can handle ranges" do
      expect(described_class.build("1-3")).to eq "0000000001-0000000003"
      expect(described_class.build("4")).to be < described_class.build("6-7")
    end

    it "is case-insensitive" do
      expect(described_class.build("9A")).to eq(described_class.build("9a"))
    end

    it "returns an empty string when the input is blank" do
      expect(described_class.build(nil)).to eq("")
      expect(described_class.build("  ")).to eq("")
    end
  end
end
