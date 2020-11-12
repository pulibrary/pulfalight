# frozen_string_literal: true
require "rails_helper"

describe "accessibility", type: :feature, js: true do
  context "home page" do
    it "complies with WCAG" do
      stub_lib_cal(id: "14275")
      stub_lib_cal(id: "12315")

      visit "/"

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding(".tt-hint") # Issue is in typeahead.js library
    end
  end

  context "research help" do
    it "complies with WCAG" do
      visit "/research_help"

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding(".tt-hint") # Issue is in typeahead.js library
    end
  end

  context "table of contents" do
    it "complies with WCAG" do
      visit "/catalog/MC221"
      # The next version of js.tree will hopefully provide accessibility
      # improvements. https://github.com/vakata/jstree/issues/2449
      expect(page).to be_axe_clean
        .within("#toc")
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .skipping(:"aria-allowed-attr") # Issue in js.tree. Role should not be "presentation".
        .skipping(:"aria-required-children") # Issue in js.tree. Children should have "treeitem" role.
    end
  end

  context "collection show page" do
    it "complies with WCAG" do
      visit "/catalog/MC221"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
    end
  end

  context "component show page" do
    it "complies with WCAG" do
      visit "/catalog/aspace_MC148_c07608"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
    end
  end
end
