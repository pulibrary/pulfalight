# frozen_string_literal: true
require "rails_helper"

RSpec.describe Arclight::Repository do
  describe "#contact_info" do
    it "returns an HTML safe string" do
      repository = described_class.all.first
      expect(repository.contact_info).to be_html_safe
    end
  end
end
