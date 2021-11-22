# frozen_string_literal: true
require "rails_helper"

require_relative "../../../lib/pulfalight/normalized_title"

describe Pulfalight::NormalizedTitle do
  describe ".new" do
    let(:title) { "Booth Tarkington Papers, 1812-1956" }
    let(:date) { "1812-1956 (mostly 1899-1946)" }
    let(:normalized_title) { described_class.new(title, date) }

    it "de-duplicates the date" do
      expect(normalized_title.to_s).to eq("Booth Tarkington Papers, 1812-1956 (mostly 1899-1946)")
    end

    context "when there is no title" do
      let(:title) { nil }
      it "just returns the date" do
        expect(normalized_title.to_s).to eq("1812-1956 (mostly 1899-1946)")
      end
    end
  end
end
