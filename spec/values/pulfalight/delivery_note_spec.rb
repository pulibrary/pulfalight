# frozen_string_literal: true

require "rails_helper"

RSpec.describe Pulfalight::DeliveryNote do
  describe "#brief_note" do
    context "when given a recap location served to the reading rooms" do
      it "returns a note about delivery times" do
        expect(described_class.new("rcpph").brief_note).to eq "This item is stored offsite. Please allow up to 3 business days for delivery."
      end
    end

    context "when given any other location" do
      it "returns nil" do
        expect(described_class.new("rcppf").brief_note).to eq nil
      end
    end
  end
end
