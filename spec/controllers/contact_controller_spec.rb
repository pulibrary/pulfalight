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
  end
end
