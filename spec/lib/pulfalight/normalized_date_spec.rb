# frozen_string_literal: true
require "rails_helper"
require_relative "../../../lib/pulfalight/year_range"
require_relative "../../../lib/pulfalight/normalized_date"

describe Pulfalight::NormalizedDate do
  describe ".new" do
    let(:inclusive) { ["1988", "2020"] }
    let(:normalized_date) { described_class.new(inclusive) }

    it "constructs a normalized date from a range of years" do
      expect(normalized_date.to_s).to eq("1988, 2020")
    end

    context "with a string containing a range of years" do
      let(:inclusive) { "  1988-2020 " }

      it "constructs a normalized date" do
        expect(normalized_date.to_s).to eq("1988-2020")
      end
    end
  end

  context "when there is a 'bulk' date" do
    let(:inclusive) { ["1812/1956"] }
    let(:bulk) { ["1899/1946"] }
    let(:other) { nil }
    let(:normalized_date) { described_class.new(inclusive, bulk, other) }

    it "constructs a normalized date using 'mostly' language" do
      expect(normalized_date.to_s).to eq("1812-1956 (mostly 1899-1946)")
    end
  end

  context "when the bulk date is not a valid range" do
    let(:inclusive) { ["1812/1956"] }
    let(:bulk) { ["1899/present"] }
    let(:other) { nil }
    let(:normalized_date) { described_class.new(inclusive, bulk, other) }

    it "formats it anyway" do
      expect(normalized_date.to_s).to eq("1812-1956 (mostly 1899-present)")
    end
  end

  context "when dates are nil" do
    let(:inclusive) { nil }
    let(:bulk) { nil }
    let(:other) { nil }
    let(:normalized_date) { described_class.new(inclusive, bulk, other) }

    it "returns nil" do
      expect(normalized_date.to_s).to be_nil
    end
  end
end
