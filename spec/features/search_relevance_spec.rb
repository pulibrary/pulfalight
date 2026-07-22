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

  context "when searching for a name that is a compound of two words" do
    it "includes results for the name without spaces" do
      visit "/?q=j+paul+bald+eagle&search_field=all_fields&group=true"
      expect(page).to have_content "J. Paul Baldeagle"
    end
  end

  context "when searching for a name with initials" do
    it "includes results if you search for the initials without spaces or punctuation" do
      visit "/?q=jm+mulvey&search_field=all_fields&group=true"
      expect(page).to have_content "A Network Planning Model for the U.S. AIR Traffic System"
    end

    it "includes results if you search for the initials with periods but no spaces" do
      visit "/?q=j.m.+mulvey&search_field=all_fields&group=true"
      expect(page).to have_content "A Network Planning Model for the U.S. AIR Traffic System"
    end

    it "includes results if you search for the initials with periods and spaces" do
      visit "/?q=j.+m.+mulvey&search_field=all_fields&group=true"
      expect(page).to have_content "A Network Planning Model for the U.S. AIR Traffic System"
    end

    it "includes results if you search for the initials with spaces but no periods" do
      visit "/?q=j+m+mulvey&search_field=all_fields&group=true"
      expect(page).to have_content "A Network Planning Model for the U.S. AIR Traffic System"
    end
  end
end
