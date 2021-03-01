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
        .excluding(".tt-hint", ".mr-auto") 
        # tt-hint issue is in typeahead.js library
        # mr-auto issue is due to axe not aware of dropshadow when checking contrast
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

  context "search results page" do
    it "complies with WCAG" do
      visit "/?utf8=✓&group=true&search_field=all_fields&q=morrison"
      # test that we got at least one collection result, so we know there is
      # content to check accessibility on; this is the class for the repository
      # name
      expect(page).to have_selector(".al-grouped-repository")
      # Blacklight icons have problems with:
      # - aria-valid-attr
      # - aria-roles
      # - duplicate-id
      # We should try including these again after upgrading blacklight (see https://github.com/pulibrary/pulfalight/issues/304)
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".blacklight-icons > svg")
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
        .skipping(:"duplicate-id") # blacklight_icon doesn't generate unique IDs
    end
  end

  context "collection show page" do
    it "complies with WCAG" do
      visit "/catalog/MC221"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".document-access > .media-body.al-online-content-icon > .blacklight-icons > svg > title") # blacklight_icon doesn't generate unique IDs
    end
  end

  context "expanded collection show page" do
    it "complies with WCAG" do
      visit "/catalog/MC221?expanded=true"
      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".document-access > .media-body.al-online-content-icon > .blacklight-icons > svg > title") # blacklight_icon doesn't generate unique IDs
    end
  end

  context "component show page" do
    it "complies with WCAG" do
      visit "/catalog/MC148_c07608"

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".document-access > .media-body.al-online-content-icon > .blacklight-icons > svg > title") # blacklight_icon doesn't generate unique IDs
    end
  end

  context "suggest a correction modal" do
    it "complies with WCAG" do
      visit "/catalog/MC148_c07608"

      # Click button for suggest a correction and wait for modal
      find("#correction-button").click
      expect(page).to have_css("#suggest_a_correction_form_box_number")

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".document-access > .media-body.al-online-content-icon > .blacklight-icons > svg > title") # blacklight_icon doesn't generate unique IDs
    end
  end

  context "ask a question modal" do
    it "complies with WCAG" do
      visit "/catalog/MC148_c07608"

      # Click button for suggest a correction and wait for modal
      find("#question-button").click
      expect(page).to have_css("#ask_a_question_form_name")

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".document-access > .media-body.al-online-content-icon > .blacklight-icons > svg > title") # blacklight_icon doesn't generate unique IDs
    end
  end

  context "request cart" do
    it "complies with WCAG" do
      visit "/catalog/MC148_c07608"

      # Click request button and wait for request cart div
      find(".add-to-cart-block").click
      expect(page).to have_css("div.request-cart")

      expect(page).to be_axe_clean
        .according_to(:wcag2a, :wcag2aa, :wcag21a, :wcag21aa)
        .excluding("#toc")
        .excluding(".tt-hint") # Issue is in typeahead.js library
        .excluding(".document-access > .media-body.al-online-content-icon > .blacklight-icons > svg > title") # blacklight_icon doesn't generate unique IDs
    end
  end
end
