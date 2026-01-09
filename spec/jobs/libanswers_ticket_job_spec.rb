# frozen_string_literal: true
require "rails_helper"

RSpec.describe LibanswersTicketJob do
  describe "#perform" do
    it "uses the libanswers api" do
      stub_libanswers_api

      message = "Your EAD components are amazing, you should say so."
      name = "Test"
      email = "test@test.org"
      box_number = "1"
      location_code = "mss"
      url = "http://example.com/catalog/1"
      user_agent = "Ruby"

      # described_class.perform_now(["C0001"])
      described_class.perform_now(
        message: message, name: name, email: email, box_number: box_number, location_code: location_code, context: url, user_agent: user_agent
      )

      expect(WebMock).to have_requested(
        :post,
        "https://faq.library.princeton.edu/api/1.1/oauth/token"
      ).with(
        body:
        "client_id=ABC&"\
        "client_secret=12345&"\
        "grant_type=client_credentials",
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Content-Type" => "application/x-www-form-urlencoded",
          "Host" => "faq.library.princeton.edu",
          "User-Agent" => "Ruby"
        }
      )

      # rubocop:disable Layout/LineLength
      expect(WebMock).to have_requested(
        :post,
        "https://faq.library.princeton.edu/api/1.1/ticket/create"
      ).with(
        body:
        /quid=3456&pquestion=Finding Aids Suggest a Correction Form&pdetails=Your EAD components are amazing, you should say so.\s*Sent from http:\/\/example.com\/catalog\/1 via LibAnswers API&pname=Test&pemail=test@test.org/,
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer abcdef1234567890abcdef1234567890abcdef12",
          "Host" => "faq.library.princeton.edu",
          "User-Agent" => "Ruby"
        }
      )
      # rubocop:enable Layout/LineLength
    end
  end
end
