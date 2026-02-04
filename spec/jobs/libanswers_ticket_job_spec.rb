# frozen_string_literal: true
require "rails_helper"

RSpec.describe LibanswersTicketJob do
  describe "#perform" do
    it "wraps the api submission " do
      submission_double = instance_double(LibanswersFormSubmission)
      allow(submission_double).to receive(:send_to_libanswers)
      allow(LibanswersFormSubmission).to receive(:new).and_return(submission_double)

      params = {
        message: "Your EAD components are amazing, you should say so.",
        name: "Test",
        email: "test@test.org",
        box_number: "1",
        location_code: "mss",
        context: "http://example.com/catalog/1",
        user_agent: "Ruby"
      }

      described_class.perform_now(**params)

      expect(LibanswersFormSubmission).to have_received(:new).with(params)
      expect(submission_double).to have_received(:send_to_libanswers)
    end
  end
end
