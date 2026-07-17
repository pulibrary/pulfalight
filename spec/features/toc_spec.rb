# frozen_string_literal: true

require "rails_helper"

describe "Table of Contents", type: :feature, js: true do
  describe "links in the table of contents" do
    it "has real href links" do
      visit "/catalog/MC221"

      expect(page).to have_css("#toc .jstree-node")

      within("#toc") do
        links = page.all("a")

        expect(links[0]["href"]).to include("/catalog/MC221_c0001")
        # Check that none of the links have href="#"
        links.each do |link|
          href = link["href"]
          expect(href).not_to eq("#")
          expect(href).not_to be_nil
          expect(href).to include("/catalog/")
        end
      end
    end
  end

  describe "online collection toggle switch" do
    it "has a toggle switch for showing materials containing online material", js: true do
      visit "/catalog//MC221"

      # Displays top-level component without online content
      expect(page).to have_content "Series 1: U.S. diplomacy career, 1900-1978"
      # Does not display nested online content component
      expect(page).not_to have_content "1929, 1929, 1931-1964"
      # Does not display nested component without online content
      expect(page).not_to have_content "Eddy, Mary P., New Testament Miniature Book, undated"

      # Click toggle to show online content only
      find(".toggle > span").click

      # Does not display top-level component without online content
      expect(page).not_to have_content "Series 1: U.S. diplomacy career, 1900-1978"
      # Displays nested online content component
      expect(page).to have_content "1929, 1929, 1931-1964"
      # Does not display nested component without online content
      expect(page).not_to have_content "Eddy, Mary P., New Testament Miniature Book, undated"

      # Clicking toggle off
      find(".toggle > span").click

      # Displays nested online content component
      expect(page).to have_content "1929, 1929, 1931-1964"
      # Displays nested component without online content
      expect(page).to have_content "Eddy, Mary P., New Testament Miniature Book, undated"
    end

    it "online toggle switch resets to off when visiting a new collection", js: true do
      visit "/catalog/C0140"

      # Displays top-level component without online content
      expect(page).to have_content "Bainbridge, William, Letter to Albert Gallatin, 1820 June 24"

      # Click toggle to show online content only
      find(".toggle > span").click

      # Does not display top-level component without online content
      expect(page).not_to have_content "Bainbridge, William, Letter to Albert Gallatin, 1820 June 24"

      new_tab = window_opened_by do
        page.execute_script('window.open("/catalog/MC221", "_blank");')
      end
      within_window new_tab do
        expect(page).to have_content "Series 1: U.S. diplomacy career, 1900-1978"
      end

      # Refreshing the old tab, containing the previous collection, should preserve that collections's online toggle state
      page.refresh

      # Displays online content
      # Note: affirmative check on the next line ensures that the page fully loads before proceeding
      expect(page).to have_content "Ball, James Presley, Photograph of a Young Chinese Scholar in Helena, Montana, circa 1888"
      # Displays only online content
      expect(page).not_to have_content "Bainbridge, William, Letter to Albert Gallatin, 1820 June 24"
    end
  end

  describe "components with a viewer" do
    it "displays an icon in the table of contents", js: true do
      visit "/catalog/MC221_c0094"
      expect(page).to have_selector "li#MC221_c0094 .online-direct-content"
    end
  end

  describe "components with many child components" do
    def child_near_top = "C1643_c3"
    def child_near_bottom = "C1643_c92"
    def parent_selector = "#C1643_c2_anchor"
    def other_parent_selector = "#C1643_c369"

    it "scrolls the child component into the scrollport", js: true do
      visit "/catalog/#{child_near_bottom}"
      expect("##{child_near_bottom}").to be_within_toc_scrollport
    end

    it "scrolls the child component into the scrollport on small screens", js: true do
      page.current_window.resize_to 972, 972
      visit "/catalog/#{child_near_bottom}"
      expect("##{child_near_bottom}").to be_within_toc_scrollport
    end

    it "shows the parent element of the selected child component", js: true do
      visit "/catalog/#{child_near_bottom}"
      expect(parent_selector).to be_within_toc_scrollport
    end

    it "does not show other components that are not the parent", js: true do
      visit "/catalog/#{child_near_bottom}"
      expect(other_parent_selector).not_to be_within_toc_scrollport
    end

    it "shows the parent element of the selected child component", js: true do
      visit "/catalog/#{child_near_top}"
      expect("##{child_near_top}").to be_within_toc_scrollport
      expect("##{child_near_bottom}").not_to be_within_toc_scrollport
      expect(parent_selector).to be_within_toc_scrollport

      execute_script "document.querySelector('##{child_near_bottom}').scrollIntoView()"
      expect("##{child_near_top}").not_to be_within_toc_scrollport
      expect("##{child_near_bottom}").to be_within_toc_scrollport
      expect(parent_selector).to be_within_toc_scrollport
    end
  end

  RSpec::Matchers.define :be_within_toc_scrollport do
    match do |selector|
      page.find selector
      evaluate_script("(function(selector) {
      const tocBox = document.querySelector('#toc').getBoundingClientRect()
      const linkBox = document.querySelector(selector).getBoundingClientRect()
      return (linkBox.top >= tocBox.top) && (linkBox.bottom <= tocBox.bottom)
  })(arguments[0]);", selector)
    end
  end
end
