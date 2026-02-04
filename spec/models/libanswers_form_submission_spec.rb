# frozen_string_literal: true
require "rails_helper"

RSpec.describe LibanswersFormSubmission do
  describe "#send_to_libanswers" do
    let(:form) do
      SuggestACorrectionForm.new
    end
    let(:submission) do
      described_class.new(
        form_params: form.serialize_params,
        form_class: form.class
      )
    end

    context "with the SuggestACorrectionForm" do
      let(:form) do
        SuggestACorrectionForm.new(
          message: "Your EAD components are amazing, you should say so.",
          name: "Test",
          email: "test@test.org",
          box_number: "1",
          location_code: "mss",
          context: "http://example.com/catalog/1",
          user_agent: "Ruby"
        )
      end

      it "uses the libanswers api" do
        stub_libanswers_api

        submission.send_to_libanswers

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

        expect(WebMock).to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
          .with(
          body:
          {
            "pdetails" => "Your EAD components are amazing, you should say so.\n\nSent from http://example.com/catalog/1 via LibAnswers API",
            "pemail" => "test@test.org",
            "pname" => "Test",
            "pquestion" => "Finding Aids Suggest a Correction Form",
            "quid" => "3456",
            "ua" => "Ruby"
          },
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer abcdef1234567890abcdef1234567890abcdef12",
            "Content-Type" => "application/x-www-form-urlencoded",
            "User-Agent" => "Ruby"
          }
        )
      end
    end

    context "with the AskAQuestionForm" do
      let(:form) do
        AskAQuestionForm.new(
          name: "Test",
          email: "test@test.org",
          subject: "reproduction",
          message: "Are your EAD components amazing?",
          location_code: "mss",
          context: "http://example.com/catalog/1",
          title: "Example Record"
        )
      end

      it "uses the libanswers api" do
        stub_libanswers_api

        submission.send_to_libanswers

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

        expect(WebMock).to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
          .with(
          body:
          {
            "pdetails" => "Are your EAD components amazing?\n\nSent from http://example.com/catalog/1 via LibAnswers API",
            "pemail" => "test@test.org",
            "pname" => "Test",
            "pquestion" => "[PULFA] reproduction",
            "quid" => "4567"
          },
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer abcdef1234567890abcdef1234567890abcdef12",
            "Content-Type" => "application/x-www-form-urlencoded",
            "User-Agent" => "Ruby"
          }
        )
      end
    end

    context "when the token can't be retrieved" do
      it "errors" do
        stub_libanswers_oauth_invalid

        expect { submission.send_to_libanswers }.to raise_error(
          OAuthService::CouldNotGenerateOAuthToken
        )
      end
    end

    context "when the message is not accepted" do
      it "errors" do
        stub_libanswers_api_invalid

        expect { submission.send_to_libanswers }.to raise_error(
          LibanswersFormSubmission::ApiSubmissionError
        )
      end
    end
  end
end
