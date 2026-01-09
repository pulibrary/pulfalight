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
    context "when the location code isn't engineering" do
      with_queue_adapter(:test)

      it "enqueues a libanswers job" do
        form = described_class.new(valid_attributes)

        form.submit
        expect(form.name).to eq ""
        expect(form.email).to eq ""
        expect(form.box_number).to eq ""
        expect(form.message).to eq ""
        expect(form.location_code).to eq "mss"
        expect(form.context).to eq "http://example.com/catalog/1"
        expect(form).to be_submitted

        expect(LibanswersTicketJob).to have_been_enqueued.with(
          message: "Your EAD components are amazing, you should say so.",
          name: "Test",
          email: "test@test.org",
          box_number: "1",
          location_code: "mss",
          context: "http://example.com/catalog/1",
          user_agent: nil
        )
      end
    end

    context "when the location code is engineering" do
      it "sends an email" do
        form = described_class.new(valid_attributes.merge({ "location_code" => "engineering library" }))

        form.submit
        expect(form.name).to eq ""
        expect(form.email).to eq ""
        expect(form.box_number).to eq ""
        expect(form.message).to eq ""
        expect(form.location_code).to eq "engineering library"
        expect(form.context).to eq "http://example.com/catalog/1"
        expect(form).to be_submitted

        expect(ActionMailer::Base.deliveries.length).to eq 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq "Suggest a Correction"
        expect(delivery.to).to eq ["wdressel@princeton.edu"]
        expect(delivery.from).to eq ["test@test.org"]
        expect(delivery.body).to include "Test"
        expect(delivery.body).to include "Your EAD components are amazing, you should say so."
        expect(delivery.body).to include "http://example.com/catalog/1"
      end
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
end
