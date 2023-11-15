# frozen_string_literal: true

require "rails_helper"

describe "Selecting search algorithms for results", type: :feature, js: false do
  context "with the search algorithms feature enabled" do
    before do
      allow(Pulfalight).to receive(:multiple_algorithms_enabled?).and_return(true)
    end

    it "renders a select widget used to select the ordering algorithm" do
      visit "/catalog?search_field=all_fields&q=diary&per_page=1"
      expect(page).to have_text("Phillips Family Papers, circa 1880-1973 (mostly 1900-1940)")

      click_button("Rank by default")
      within("#online_content.dropdown-help-text") do
        expect(page).to have_text("records with direct online content are first")
      end
      click_link("online content")
      expect(page).to have_button("Rank by online content")
      expect(page).to have_text("Harold B. Hoskins Diaries, 1899-1965")
    end
  end

  context "with the search algorithms feature disabled" do
    before do
      allow(Pulfalight).to receive(:multiple_algorithms_enabled?).and_return(false)
    end

    it "does not render a select widget" do
      visit "/catalog?search_field=all_fields&q=diary&per_page=1"
      expect(page).not_to have_button("Rank by default")
    end
  end
end
