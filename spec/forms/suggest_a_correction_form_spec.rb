# frozen_string_literal: true
require "rails_helper"

RSpec.describe SuggestACorrectionForm do
  let(:valid_attributes) do
    {
      "name" => "Test",
      "email" => "test@test.org",
      "box_number" => "1",
      "message" => "This is so broken.",
      "location_code" => "mss"
    }
  end
  describe "initialization" do
    it "takes a name, email, box/container number, and message" do
      form = described_class.new(valid_attributes)

      expect(form.name).to eq "Test"
      expect(form.email).to eq "test@test.org"
      expect(form.box_number).to eq "1"
      expect(form.message).to eq "This is so broken."
      expect(form.location_code).to eq "mss"

      expect(form).to be_valid
    end
  end
  describe "validations" do
    it "is invalid without a name" do
      form = described_class.new(valid_attributes.merge("name" => ""))
      expect(form).not_to be_valid
    end
    it "is invalid without an email" do
      form = described_class.new(valid_attributes.merge("email" => ""))
      expect(form).not_to be_valid
    end
    it "is invalid without a message" do
      form = described_class.new(valid_attributes.merge("message" => ""))
      expect(form).not_to be_valid
    end
  end

  describe "#routed_mail_to" do
    ["mss", "cotsen", "eng", "lae", "rarebooks", "selectors"].each do |location_code|
      it "routes to mssdiv@princeton.edu for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "mssdiv@princeton.edu"
      end
    end
    ["mudd", "publicpolicy", "univarchives"].each do |location_code|
      it "routes to muddts@princeton.edu for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "muddts@princeton.edu"
      end
    end
    it "routes to rbsc@princeton.edu for rbsc" do
      form = described_class.new(valid_attributes.merge("location_code" => "rbsc"))
      expect(form.routed_mail_to).to eq "rbsc@princeton.edu"
    end
    it "routes to wdressel@princeton.edu for engineering library" do
      form = described_class.new(valid_attributes.merge("location_code" => "engineering library"))
      expect(form.routed_mail_to).to eq "wdressel@princeton.edu"
    end
  end
end
