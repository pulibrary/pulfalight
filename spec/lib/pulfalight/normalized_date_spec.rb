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
end
