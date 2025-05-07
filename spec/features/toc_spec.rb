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
  end

  describe "components with a viewer" do
    it "displays an icon in the table of contents", js: true do
      visit "/catalog/MC221_c0094"
      expect(page).to have_selector "li#MC221_c0094 .online-direct-content"
    end
  end
end
