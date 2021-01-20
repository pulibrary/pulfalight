# frozen_string_literal: true
require "rails_helper"

describe "faceted searches", type: :feature, js: true do
  context "with limited facets for date ranges" do
    before do
      visit "/?search_field=all_fields&q="
    end

    it "renders a histogram plot" do
      expect(page).to have_css("#facet-date_range_sim .chart_js", visible: false)
    end

    it "renders the number of dated search result items" do
      expect(page).to have_css("#facet-date_range_sim #range_date_range_sim_begin", visible: false)
      expect(page).to have_css("#facet-date_range_sim #range_date_range_sim_end", visible: false)
    end

    it "renders the number of undated search result items" do
      expect(page).to have_css("#facet-date_range_sim .missing", text: /Unknown/, visible: false)
    end
  end

  describe "access facet" do
    before do
      visit "/?search_field=all_fields&q="
    end

    it "displays access values and is always open" do
      expect(page).to have_selector("h3.facet-field-heading:first-child button", text: "Access", visible: false)
      expect(page).to have_selector("#facet-has_online_content_ssim.show", visible: false)
      expect(page).to have_selector("a.facet-select", text: "Online", visible: false)
    end
  end
end
