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

  context "when a collection matches the query only on a non-title field" do
    it "does not boost the collection above a title match" do
      visit "?q=dogs&search_field=all_fields"
      first_result = find(".al-search-result-index-article h3", match: :first)
      expect(first_result).to have_text("Hark! Hark! The Dogs Do Bark")
      expect(first_result).not_to have_text("Victorian Novelists")
    end
  end
end
