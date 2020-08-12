# frozen_string_literal: true
require "rails_helper"

describe "user search history", type: :feature, js: true do
  context "when viewing the search history as an anonymous user" do
    before do
      visit "/?search_field=all_fields&q=Lilienthal"
      visit "/search_history"
    end

    it "renders link to the previous search" do
      expect(page).to have_css("td.query a", text: "Lilienthal")
    end
  end
end
