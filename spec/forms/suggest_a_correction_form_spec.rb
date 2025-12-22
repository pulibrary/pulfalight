# frozen_string_literal: true
require "rails_helper"

RSpec.describe SuggestACorrectionForm do
  let(:valid_attributes) do
    {
      "name" => "Test",
      "email" => "test@test.org",
      "box_number" => "1",
      "message" => "Your EAD components are amazing, you should say so.",
      "location_code" => "mss",
      "context" => "http://example.com/catalog/1"
    }
  end
  describe "initialization" do
    it "takes a name, email, box/container number, and message" do
      form = described_class.new(valid_attributes)

      expect(form.name).to eq "Test"
      expect(form.email).to eq "test@test.org"
      expect(form.box_number).to eq "1"
      expect(form.message).to eq "Your EAD components are amazing, you should say so."
      expect(form.location_code).to eq "mss"

      expect(form).to be_valid
    end
  end

  describe "submit" do
    it "sends an email and resets its attributes, setting itself as submitted" do
      stub_libanswers_api
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
      
      expect(WebMock).to have_requested(
        :post,
        'https://faq.library.princeton.edu/api/1.1/ticket/create'
      ).with(body: 'quid=3456&'\
      'pquestion=[Finding Aids] Example Record&'\
      "pdetails=You should fix the thumbnail\n\nSent from http://example.com/catalog/1 via LibAnswers API&"\
      'pname=Test&'\
      'pemail=test@test.org',
             headers: { Authorization: 'Bearer abcdef1234567890abcdef1234567890abcdef12' })
    end
  end

  describe "validations" do
    it "is valid without a name" do
      form = described_class.new(valid_attributes.merge("name" => ""))
      expect(form).to be_valid
    end
    it "is valid without an email" do
      form = described_class.new(valid_attributes.merge("email" => ""))
      expect(form).to be_valid
    end
    it "emails provided are invalid if not well-formed" do
      form = described_class.new(valid_attributes.merge("email" => "test"))
      expect(form).not_to be_valid
    end
    it "is invalid without a message" do
      form = described_class.new(valid_attributes.merge("message" => ""))
      expect(form).not_to be_valid
    end
  end

  describe "#routed_mail_to" do
    ["mss", "cotsen", "eng", "lae", "rarebooks", "selectors", "mudd", "publicpolicy", "univarchives", "rbsc"].each do |location_code|
      it "uses Libanswers API to route messages for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(WebMock).to have_requested(
          :post,
          'https://faq.library.princeton.edu/api/1.1/ticket/create'
        ).with(body: 'quid=3456&'\
        'pquestion=[Finding Aids] Example Record&'\
        "pdetails=You should fix the thumbnail\n\nSent from http://example.com/catalog/1 via LibAnswers API&"\
        'pname=Test&'\
        'pemail=test@test.org',
        headers: { Authorization: 'Bearer abcdef1234567890abcdef1234567890abcdef12' })
      end
    end
    it "routes to wdressel@princeton.edu for engineering library" do
      form = described_class.new(valid_attributes.merge("location_code" => "engineering library"))
      expect(form.routed_mail_to).to eq "wdressel@princeton.edu"
    end
  end
end
