# frozen_string_literal: true
require "rails_helper"

RSpec.describe ContactController do
  render_views
  describe "POST suggest" do
    context "when given invalid data" do
      it "returns the form re-rendered" do
        post :suggest, params: { suggest_a_correction_form: { "name" => "Test" } }

        expect(response.status).to eq 422

        expect(response.body).to have_field "Name"
        expect(response.body).to have_content "Message can't be blank"
      end
    end

    it "doesn't require an email address" do
      post :suggest, params: {
        suggest_a_correction_form: {
          "name" => "Bill Nye",
          "email" => "",
          "box_number" => "1",
          "message" => "This record needs more science.",
          "context" => "http://example.com/example",
          "location_code" => "engineering library"
        }
      }

      expect(response.status).to eq 200
      expect(response.body).to have_field "Name", with: ""
      expect(response.body).to have_content "Thank you for submitting"
    end
  end

  describe "POST question" do
    context "when given invalid data" do
      it "returns the form re-rendered" do
        post :question, params: { ask_a_question_form: { "name" => "Test" } }

        expect(response.status).to eq 422

        expect(response.body).to have_field "Name"
        expect(response.body).to have_content "Email can't be blank"
      end
    end
  end
end
