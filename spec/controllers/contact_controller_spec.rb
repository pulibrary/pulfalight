# frozen_string_literal: true
require "rails_helper"

RSpec.describe ContactController do
  render_views
  let(:invalid_attributes) do
    {
      "name" => "Test"
    }
  end
  describe "POST suggest" do
    context "when given invalid data" do
      it "returns the form re-rendered" do
        stub_libanswers_api_invalid
        form = SuggestACorrectionForm.new(invalid_attributes)
        form.submit

        # post :suggest, params: { suggest_a_correction_form: { "name" => "Test" } }

        # rubocop:disable Layout/LineLength
        expect(WebMock).to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/oauth/token"
        ).with(
          body:
            "client_id=ABC&"\
            "client_secret=12345&"\
            "grant_type=client_credentials",
          headers: {
            "Accept" => "*/*", "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "Content-Type" => "application/x-www-form-urlencoded", "Host" => "faq.library.princeton.edu", "User-Agent" => "Ruby"
          }
        )

        # rubocop:disable Layout/LineLength
        expect(WebMock).to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        ).with(
          body:
            /quid=3456&pquestion=Finding Aids Suggest a Correction Form&pdetails=\s*Sent via LibAnswers API&pname=Test/,
          headers: {
            "Accept" => "*/*", "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3", "Authorization" => "Bearer abcdef1234567890abcdef1234567890abcdef12", "Host" => "faq.library.princeton.edu", "User-Agent" => "Ruby"
          }
        )

        expect(response.status).to eq 200

        expect(response.body).to have_field "Name"
        expect(response.body).to have_content "Message can't be blank"
      end
    end

    context "when given valid params" do
      it "returns a 200 and sends an email appropriately" do
        post :suggest, params: {
          suggest_a_correction_form: {
            "name" => "Bill Nye",
            "email" => "thescienceguy@example.com",
            "message" => "This record needs more science.",
            "context" => "http://example.com/example",
            "location_code" => "mudd"
          }
        }

        expect(response.status).to eq 200
        expect(response.body).to have_field "Name", with: ""
        expect(response.body).to have_content "Thank you for submitting"

        expect(ActionMailer::Base.deliveries.length).to eq 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq "Suggest a Correction"
        expect(delivery.to).to eq ["suggestacorrection@princeton.libanswers.com"]
        expect(delivery.from).to eq ["thescienceguy@example.com"]
        expect(delivery.body).to include "Bill Nye"
        expect(delivery.body).to include "This record needs more science."
        expect(delivery.body).to include "http://example.com/example"
      end

      it "doesn't require an email address" do
        post :suggest, params: {
          suggest_a_correction_form: {
            "name" => "Bill Nye",
            "email" => "",
            "box_number" => "1",
            "message" => "This record needs more science.",
            "context" => "http://example.com/example",
            "location_code" => "mudd"
          }
        }

        expect(response.status).to eq 200
        expect(response.body).to have_field "Name", with: ""
        expect(response.body).to have_content "Thank you for submitting"

        expect(ActionMailer::Base.deliveries.length).to eq 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq "Suggest a Correction"
        expect(delivery.to).to eq ["suggestacorrection@princeton.libanswers.com"]
        expect(delivery.from).to eq ["no-reply@localhost"]
        expect(delivery.body).to include "Bill Nye"
        expect(delivery.body).to include "This record needs more science."
        expect(delivery.body).to include "http://example.com/example"
      end
    end
  end

  describe "POST question" do
    context "when given invalid data AJAX data" do
      it "returns the form re-rendered" do
        post :question, params: { ask_a_question_form: { "name" => "Test" } }

        expect(response.status).to eq 422

        expect(response.body).to have_field "Name"
        expect(response.body).to have_content "Email can't be blank"
      end
    end

    context "when given valid params" do
      it "returns a 200 and sends an email appropriately" do
        post :question, params: {
          ask_a_question_form: {
            "name" => "Bill Nye",
            "email" => "thescienceguy@example.com",
            "message" => "This record needs more science.",
            "context" => "http://example.com/example",
            "location_code" => "mudd",
            "subject" => "collection",
            "title" => "stuff"
          }
        }

        expect(response.status).to eq 200
        expect(response.body).to have_field "Name", with: ""
        expect(response.body).to have_content "Thank you for submitting your question to Special Collections."

        expect(ActionMailer::Base.deliveries.length).to eq 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq "[PULFA] stuff"
        expect(delivery.to).to eq ["specialcollections@princeton.libanswers.com"]
        expect(delivery.from).to eq ["thescienceguy@example.com"]
        expect(delivery.body).to include "Bill Nye"
        expect(delivery.body).to include "This record needs more science."
        expect(delivery.body).to include "http://example.com/example"
      end
    end
  end
end
