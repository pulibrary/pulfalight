# frozen_string_literal: true
require "rails_helper"

describe "catalog searches", type: :feature, js: true do
  context "when searching for a specific collection by ID" do
    before do
      visit "/?search_field=all_fields&q=WC127"
    end

    it "renders all collection extents on the collection show page" do
      expect(page).to have_text("1.5 linear feet")
      expect(page).to have_text("1 box")
    end
  end

  context "when searching for an unpublished collection or component", js: false do
    it "does not return it" do
      visit "/?search_field=all_fields&q=c0744.04"
      expect(page).to have_content "No results found for your search"
    end
    it "doesn't return a show page" do
      visit "/catalog/C0744-04"
      expect(page).to have_content "The page you were looking for doesn't exist."
    end
    it "doesn't normally return JSON" do
      visit "/catalog/C0744-04_c0117.json"
      expect(page).to have_content "Not Found"
    end
    it "returns JSON if given an auth token" do
      visit "/catalog/C0744-04_c0117.json?auth_token=#{Pulfalight.config['unpublished_auth_token']}"
      expect(page).to have_content "Garrett Ethiopic Magic Scroll No. 23"
    end
  end

  context "when searching for a specific collection by title", js: false do
    before do
      visit "/?search_field=all_fields&q=david+e.+lilienthal+papers%2C+1900-1981"
    end

    it "renders all collection extents in the collection search results" do
      expect(page).to have_text("4 items")
      expect(page).to have_text("632 boxes")
    end
    it "renders the call number/title" do
      expect(page).to have_content "MC148"
      within first("h3") do
        expect(page).to have_content "David E. Lilienthal Papers"
      end
    end
    it "returns all components in that collection", js: false do
      visit "/?search_field=all_fields&group=false&q=Walter Dundas Bathurst Papers"
      expect(page).to have_text("17 entries")
    end
  end

  context "when displaying grouped results", js: false do
    it "renders components with their descriptions" do
      visit "/?search_field=all_fields&group=true&q=david+e.+lilienthal+papers%2C+1900-1981"

      expect(page).to have_content "mostly professional correspondence to and from Lilienthal"
    end
  end

  context "when searching using the search form" do
    it "returns search results grouped by collection as a default" do
      visit "/?q=&search_field=all_fields"
      find("#search").click
      expect(page).to have_current_path(/group=true/)
    end

    context "when faceting by collection" do
      it "does not return results grouped by collection" do
        visit "/?f%5Bcollection_sim%5D%5B%5D=Barr+Ferree+collection%2C+1880-1929&group=true"
        expect(page).not_to have_selector(".al-grouped-title-bar")
      end
    end
  end

  context "when searching by date" do
    it "provides a helpful message if the date query is invalid" do
      visit "/?utf8=%E2%9C%93&group=true&search_field=all_fields&q=&range%5Bdate_range_sim%5D%5Bbegin%5D=1900&range%5Bdate_range_sim%5D%5Bend%5D=1800&commit=Limit"
      expect(page).to have_text("The start year must be before the end year.")
    end
  end
end
