# frozen_string_literal: true
require "rails_helper"

RSpec.describe AskAQuestionForm do
  let(:valid_attributes) do
    {
      "name" => "Test",
      "email" => "test@test.org",
      "subject" => "reproduction",
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
      expect(form.subject).to eq "reproduction"
      expect(form.message).to eq "Your EAD components are amazing, you should say so."
      expect(form.location_code).to eq "mss"
      expect(form.context).to eq "http://example.com/catalog/1"
      expect(form.title).to eq "Example Record"

      expect(form).to be_valid
    end
  end

  describe "#email_subject" do
    it "depends on the drop down" do
      form = described_class.new(valid_attributes)
      ["reproduction", "permission", "access", "how much"].each do |subject_type|
        form.subject = subject_type
        expect(form.email_subject).to eq "[PULFA] #{subject_type}"
      end
      form.subject = "collection"
      expect(form.email_subject).to eq "[PULFA] Example Record"
    end
  end

  describe "submit" do
    it "sends an email and resets its attributes, setting itself as submitted" do
      form = described_class.new(valid_attributes)

      form.submit
      expect(ActionMailer::Base.deliveries.length).to eq 1
      expect(form.name).to eq ""
      expect(form.email).to eq ""
      expect(form.message).to eq ""
      expect(form.location_code).to eq "mss"
      expect(form.context).to eq "http://example.com/catalog/1"
      expect(form.title).to eq "Example Record"
      expect(form).to be_submitted

      mail = ActionMailer::Base.deliveries.first
      expect(mail.subject).to eq "[PULFA] reproduction"
      expect(mail.from).to eq ["test@test.org"]
      expect(mail.body).to include "Name: Test"
      expect(mail.body).to include "Email: test@test.org"
      expect(mail.body).to include "Subject: reproduction"
      expect(mail.body).to include "Comments: Your EAD components are amazing"
      expect(mail.body).to include "Context: http://example.com/catalog/1"
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
    ["mudd", "publicpolicy", "univarchives", "rbsc", "lae", "mss", "rarebooks", "ga"].each do |location_code|
      it "routes to specialcollections@princeton.libanswers.com for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "specialcollections@princeton.libanswers.com"
      end
    end
    ["eng", "engineering library"].each do |location_code|
      it "routes to wdressel@princeton.edu for #{location_code}" do
        form = described_class.new(valid_attributes.merge("location_code" => location_code))
        expect(form.routed_mail_to).to eq "wdressel@princeton.edu"
      end
    end
  end
end
