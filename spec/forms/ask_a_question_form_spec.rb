# frozen_string_literal: true
require "rails_helper"

RSpec.describe AskAQuestionForm do
  let(:valid_attributes) do
    {
      "name" => "Test",
      "email" => "test@test.org",
      "subject" => "Reproduction & Photocopies",
      "message" => "Your EAD components are amazing, you should say so.",
      "location_code" => "mss",
      "context" => "http://example.com/catalog/1",
      "title" => "Example Record"
    }
  end
  describe "initialization" do
    it "takes a name, email, subject, message, location_code, and context" do
      form = described_class.new(valid_attributes)

      expect(form.name).to eq "Test"
      expect(form.email).to eq "test@test.org"
      expect(form.subject).to eq "Reproduction & Photocopies"
      expect(form.message).to eq "Your EAD components are amazing, you should say so."
      expect(form.location_code).to eq "mss"
      expect(form.context).to eq "http://example.com/catalog/1"
      expect(form.title).to eq "Example Record"

      expect(form).to be_valid
    end
  end

  describe "submit" do
    xit "sends an email and resets its attributes, setting itself as submitted" do
      form = described_class.new(valid_attributes)

      form.submit
      expect(ActionMailer::Base.deliveries.length).to eq 1
      expect(form.name).to eq ""
      expect(form.email).to eq ""
      expect(form.box_number).to eq ""
      expect(form.message).to eq ""
      expect(form.location_code).to eq "mss"
      expect(form.context).to eq "http://example.com/catalog/1"
      expect(form).to be_submitted
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
    it "is invalid wtihout an email-looking email" do
      form = described_class.new(valid_attributes.merge("email" => "test"))
      expect(form).not_to be_valid
    end
    it "is invalid without a message" do
      form = described_class.new(valid_attributes.merge("message" => ""))
      expect(form).not_to be_valid
    end
  end

  describe "#routed_mail_to" do
    ["rbsc", "lae", "mss", "rarebooks"].each do |location_code|
      it "routes to rbsc@princeton.edu for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "rbsc@princeton.edu"
      end
    end
    ["mudd", "publicpolicy", "univarchives"].each do |location_code|
      it "routes to mudd@princeton.edu for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "mudd@princeton.edu"
      end
    end
    ["eng", "engineering library"].each do |location_code|
      it "routes to wdressel@princeton.edu for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "wdressel@princeton.edu"
      end
    end
    it "routes to jmellby@princeton.edu for ga" do
      form = described_class.new(valid_attributes.merge("location_code" => "ga"))
      expect(form.routed_mail_to).to eq "jmellby@princeton.edu"
    end
  end
end
