# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Table of Contents links", type: :feature, js: true do
  describe "links in the table of contents" do
    it "have real hrefs, not just '#'" do
      # Visit a collection page that has a table of contents
      visit "/catalog/AC198"

      # Wait for the TOC to load (it's loaded via JavaScript)
      expect(page).to have_css("#toc")

      # Wait for the jsTree to be initialized and nodes to be loaded
      expect(page).to have_css("#toc .jstree-node", wait: 10)

      # Check that the links in the TOC have real hrefs, not just '#'
      within("#toc") do
        # Get all links in the TOC
        links = page.all("a")
        
        # Make sure we have at least one link
        expect(links.length).to be > 0
        
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
end