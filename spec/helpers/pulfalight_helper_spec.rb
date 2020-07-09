# frozen_string_literal: true
require "rails_helper"

describe PulfalightHelper, type: :helper do
  describe "#current_year" do
    it "returns the current year" do
      expect(helper.current_year).to eq DateTime.current.year
    end
  end
end
