# frozen_string_literal: true
require "rails_helper"

describe "search relevance", type: :feature, js: true do
  context "when searching for a specific collection by keyword" do
    before do
      visit "/?q=james+baker&search_field=all_fields&group=true"
    end

    it "ranks results with the keyword in the collection title above other results" do
      first_collection = find(".al-grouped-results h3", match: :first)
      expect(first_collection).to have_text("James A. Baker III Papers")
    end
  end
end
