# frozen_string_literal: true
require "rails_helper"

RSpec.describe ContactController do
  render_views
  describe "POST suggest" do
    context "when given invalid data AJAX data" do
      it "returns the form re-rendered" do
        post :suggest, params: { suggest_a_correction_form: { "name" => "Test" } }

        expect(response.status).to eq 422

        expect(response.body).to have_field "Name"
        expect(response.body).to have_content "Email can't be blank"
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
        expect(response.body).to have_content "Thank you for your submission."

        expect(ActionMailer::Base.deliveries.length).to eq 1
        delivery = ActionMailer::Base.deliveries.first
        expect(delivery.subject).to eq "Suggest a Correction"
        expect(delivery.to).to eq ["muddts@princeton.edu"]
        expect(delivery.from).to eq ["no-reply@localhost"]
        expect(delivery.body).to include "Bill Nye"
        expect(delivery.body).to include "This record needs more science."
        expect(delivery.body).to include "http://example.com/example"
      end
    end
  end
end
