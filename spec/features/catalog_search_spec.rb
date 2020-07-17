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

  context "when searching for a specific collection by title" do
    before do
      visit "/?search_field=all_fields&q=david+e.+lilienthal+papers%2C+1900-1981%2C+bulk+1950%2F1981"
    end

    it "renders all collection extents in the collection search results" do
      expect(page).to have_text("278.9 linear feet")
      expect(page).to have_text("632 boxes and 2 oversize folders")
    end
  end
end
