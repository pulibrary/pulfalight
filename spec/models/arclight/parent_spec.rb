# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arclight::Parent do
  describe "#global_id" do
    it "returns just the ID" do
      parent = described_class.new(id: "test", label: "Test", eadid: "2", level: 2)
      expect(parent.global_id).to eq "test"
    end
  end
end
