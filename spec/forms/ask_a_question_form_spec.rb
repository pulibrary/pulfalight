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
  let(:valid_attributes_engineering) do
    {
      "name" => "Test",
      "email" => "test@test.org",
      "subject" => "engineering resource",
      "message" => "Your EAD components are amazing, you should say so.",
      "location_code" => "engineering library",
      "context" => "http://example.com/catalog/1",
      "title" => "Example Engineering Record"
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
    context "when the location code isn't engineering" do
      with_queue_adapter(:test)

      it "enqueues a libanswers job" do
        form = described_class.new(valid_attributes)

        form.submit
        expect(form.name).to eq ""
        expect(form.email).to eq ""
        expect(form.message).to eq ""
        expect(form.location_code).to eq "mss"
        expect(form.context).to eq "http://example.com/catalog/1"
        expect(form.title).to eq "Example Record"
        expect(form).to be_submitted

        expect(LibanswersTicketJob).to have_been_enqueued.with(
          form_params: {
            "name" => "Test",
            "email" => "test@test.org",
            "subject" => "reproduction",
            "message" => "Your EAD components are amazing, you should say so.",
            "location_code" => "mss",
            "context" => "http://example.com/catalog/1",
            "title" => "Example Record"
          },
          form_class: described_class
        )
      end
    end

    context "when the location code is engineering" do
      with_queue_adapter(:test)

      it "enqueues a libanswers job" do
        form = described_class.new(valid_attributes_engineering)

        form.submit
        expect(form.name).to eq ""
        expect(form.email).to eq ""
        expect(form.message).to eq ""
        expect(form.location_code).to eq "engineering library"
        expect(form.context).to eq "http://example.com/catalog/1"
        expect(form.title).to eq "Example Engineering Record"
        expect(form).to be_submitted

        expect(LibanswersTicketJob).to have_been_enqueued.with(
          form_params: {
            "name" => "Test",
            "email" => "test@test.org",
            "subject" => "engineering resource",
            "message" => "Your EAD components are amazing, you should say so.",
            "location_code" => "engineering library",
            "context" => "http://example.com/catalog/1",
            "title" => "Example Engineering Record"
          },
          form_class: described_class
        )
      end
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
    it "is valid when the honeypot is filled in, so that the robots are fooled" do
      form = described_class.new(valid_attributes.merge("feedback" => "12345"))
      expect(form).to be_valid
    end
  end
end
