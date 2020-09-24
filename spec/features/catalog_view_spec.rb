# frozen_string_literal: true

require "rails_helper"

describe "viewing catalog records", type: :feature, js: true do
  context "when viewing a component show page" do
    it "renders a collection title as a link without a separate date element" do
      visit "catalog/MC221_c0059"
      expect(page).to have_css(".collection.title a span", text: "Harold B. Hoskins Papers, 1822-1982")
      expect(page).not_to have_css(".collection-attributes h2.media span.col")
    end
  end
  context "when viewing a component which can be requested from Aeon" do
    xit "renders a request button" do
      visit "/catalog/MC148_c00001"

      # This is now blocked by the Request Cart Vue integration
    end

    xit "generates a request <form>" do
      visit "/catalog/aspace_WC064_c1"

      # This is now blocked by the Request Cart Vue integration
    end

    context "with extent provided" do
      xit "maps this to the <form> <input>" do
        visit "/catalog/MC148_c00001"

        # This is now blocked by the Request Cart Vue integration
      end
    end
  end
  context "with a component show page" do
    before do
      visit "/catalog/MC221_c0060"
    end

    it "has a table of contents element" do
      expect(page).to have_css("#toc")
    end

    it "does not have breadcrumbs" do
      expect(page).not_to have_css("ol.breadcrumb")
    end

    it "has a collection history tab" do
      expect(page.body).to include "Scott Rodman approved the gifting to Mudd"
      expect(page.body).to include "Gifted to the American Heritage Center"
      expect(page.body).to include "boxes of books were separated during processing in 2007"
      expect(page.body).to include "A preliminary inventory list, MARC record and collection-level description"
      expect(page.body).to include "These papers were processed with the generous support"
    end

    it "has a collection access tab" do
      expect(page.body).to include "The collection is open for research use."
      expect(page.body).to include "Single photocopies may be made for research purposes"
      expect(page.body).to include "Public Policy Papers, Department of Special Collections"
      expect(page.body).to include "65 Olden Street"
      expect(page.body).to include "(609) 258-6345"
    end

    it "has a find related materials tab" do
      expect(page.body).to include "20th century"
      expect(page.body).to include "Foreign Service Institute"
      expect(page.body).to include "Middle East -- Politics"
    end
    context "which has a viewer", js: false do
      before do
        visit "/catalog/MC221_c0094"
      end
      it "displays the viewer" do
        expect(page).to have_css(".uv__overlay")
      end
    end
  end
  context "with a collection show page" do
    before do
      visit "/catalog/MC221"
    end

    it "has overview and abstract summary sections" do
      expect(page).to have_css(".blacklight-creators_ssim a", text: "Hoskins")
      expect(page).to have_css("dd.blacklight-title_ssm", text: "Harold B. Hoskins Papers")
      expect(page).to have_css("dd.blacklight-normalized_date_ssm", text: "1822-1982")
      expect(page).to have_css("dd.blacklight-extent_ssm", text: "14 linear feet and 17 boxes")
      expect(page).to have_text("Harold Boies Hoskins was a businessman")
    end
    xit "has a language property in the overview summary section" do
      # TODO: ensure that collection language is indexed correctly
      expect(page).to have_css("dd.blacklight-language_ssm", text: "English")
    end

    it "has description and creator biography metadata" do
      expect(page.body).to include "The Harold B. Hoskins Papers consist of correspondence"
      expect(page.body).to include "Harold Boies Hoskins was a businessman, diplomat, and educator"
    end

    it "has a collection history tab" do
      expect(page.body).to include "Scott Rodman approved the gifting to Mudd"
      expect(page.body).to include "Gifted to the American Heritage Center"
      expect(page.body).to include "boxes of books were separated during processing in 2007"
      expect(page.body).to include "A preliminary inventory list, MARC record and collection-level description"
      expect(page.body).to include "These papers were processed with the generous support"
    end

    it "has a collection access tab" do
      expect(page.body).to include "The collection is open for research use."
      expect(page.body).to include "Single photocopies may be made for research purposes"
      expect(page.body).to include "Harold B. Hoskins Papers; Public Policy Papers, Department of Special Collections"
      expect(page.body).to include "65 Olden Street"
      expect(page.body).to include "(609) 258-6345"
    end

    it "has a find related materials tab" do
      expect(page.body).to include "20th century"
      expect(page.body).to include "Foreign Service Institute"
      expect(page.body).to include "Middle East -- Politics"
    end
  end
end
