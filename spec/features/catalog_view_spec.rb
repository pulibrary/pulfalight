# frozen_string_literal: true

require "rails_helper"

describe "viewing catalog records", type: :feature, js: true do
  context "when viewing a component show page" do
    it "renders a collection title as a link without a separate date element" do
      visit "catalog/MC221_c0059"
      expect(page).to have_css(".collection.title a span", text: "Harold B. Hoskins Papers, 1822-1982")
      expect(page).not_to have_css(".collection-attributes h2.media span.col")
    end
    it "renders a component title with a correctly formatted date" do
      visit "catalog/C1588_c9"
      expect(page).to have_css(".document-title > h2", text: "Unused AIC Supply Request Form, circa 1885")
    end
    it "has a suggest a correction form", js: false do
      visit "catalog/MC221_c0059"

      expect(page).to have_field "suggest_a_correction_form_location_code", visible: false, type: :hidden, with: "publicpolicy"
      expect(page).to have_field "suggest_a_correction_form_context", visible: false, type: :hidden, with: "http://www.example.com/catalog/MC221_c0059"
    end
    it "has an ask a question form", js: false do
      visit "catalog/MC221_c0059"

      expect(page).to have_selector "h5", text: "Ask a Question"
      expect(page).to have_field "ask_a_question_form_location_code", visible: false, type: :hidden, with: "publicpolicy"
      expect(page).to have_field "ask_a_question_form_context", visible: false, type: :hidden, with: "http://www.example.com/catalog/MC221_c0059"
      expect(page).to have_field "ask_a_question_form_title", visible: false, type: :hidden, with: "Harold B. Hoskins Papers, 1822-1982"
    end
    it "has a collection level storage note when there is only one location" do
      visit "catalog/MC221_c0059"
      expect(page).to have_content("Storage Note:")
      expect(page).to have_content("This collection is stored at the Mudd Manuscript Library.")
      expect(page).to have_link("Special Collections Mudd Reading Room", href: "https://library.princeton.edu/special-collections/mudd")
    end
    it "has a collection level storage note when there are multiple storage notes" do
      visit "catalog/C1387_c1"
      expect(page).to have_content("Storage Note:")
      expect(page).to have_content("This collection is stored at ReCAP and Firestone Library.")
      expect(page).to have_content("This collection is stored partially (Boxes 1-2, 5-6) on-site at Firestone Library and partially off-site (Boxes 3-4) at ReCAP.")
    end
    it "displays cabinet and drawer locations when those exist" do
      visit "catalog/AC154_c03425"
      expect(page).to have_content("Located In:")
      expect(page).to have_content("Folder Oversize folder 103 cabinet 3 drawer 15, Folder 104 cabinet 3 drawer 15, Folder 105 cabinet 3 drawer 15, Folder 106 cabinet 3 drawer 15")
    end
    it "formats a 'mostly' date" do
      visit "catalog/C0062"
      expect(page).to have_content("Booth Tarkington Papers, 1812-1956 (mostly 1899-1946)")
    end
  end
  context "when viewing a component which can be requested from Aeon" do
    it "renders a request button which opens a request cart form" do
      visit "/catalog/MC148_c00002"

      find(".add-to-cart-block").click
      within(".request-cart") do
        expect(page).to have_selector "button.denied-button"
        expect(page).to have_selector "#item-MC148_c00002"
        expect(page).to have_selector "td", text: /1918/
        expect(page).to have_selector "td", text: /MC148_c00002/
        expect(page).to have_selector "td", text: /Box 1/
        expect(page).to have_selector "button[type='submit']", text: /Request 1 Item/

        # Click the remove item button
        find("#item-MC148_c00002 > td > button").click
      end

      expect(page).to have_selector ".cart-view-toggle-block > div > button"
      # Open the cart again
      find(".cart-view-toggle-block > div > button").click
      within(".request-cart") do
        # Check that it is empty
        expect(page).to have_selector "button[type='submit']", text: /No Items in Your Cart/

        # Check that it can be closed
        expect(page).to have_selector "button.denied-button"
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

    context "which has a viewer", js: false do
      before do
        visit "/catalog/MC221_c0094"
      end
      it "displays the viewer" do
        expect(page).to have_css(".uv__overlay")
      end
      it "displays 'Has Online Content' at the collection level" do
        visit "/catalog/MC221"
        expect(page).to have_selector(".document-access.online-content", text: "Has Online Content")
      end
      it "displays an icon in the table of contents", js: true do
        expect(page).to have_selector "li#MC221_c0094 .al-online-content-icon"
      end
    end
  end
  context "when given something with access restrictions", js: false do
    it "displays 'Restricted' at the collection level" do
      visit "/catalog/C0187"
      expect(page).to have_selector(".document-access.restricted", text: "Restricted Content")
    end
    it "displays 'Some Restricted' at the collection level and restricted at the component level" do
      visit "/catalog/AC136_c2889"
      expect(page).to have_selector(".document-access.some-restricted", text: "Some Restricted Content")
      expect(page).to have_selector("#component-summary .document-access.restricted", text: "Restricted Content")
    end
  end
  context "with a no-digital-content collection show page" do
    it "doesn't display Has Online Content", js: false do
      visit "/catalog/MC152"
      expect(page).not_to have_selector(".document-access.online-content", text: "Has Online Content")
    end
  end
  context "with a collection show page" do
    before do
      visit "/catalog/MC221"
    end

    it "has an ask a question button", js: false do
      expect(page).to have_selector "#question-button"
      expect(page).to have_field "ask_a_question_form_location_code", visible: false, type: :hidden, with: "publicpolicy"
      expect(page).to have_field "ask_a_question_form_context", visible: false, type: :hidden, with: "http://www.example.com/catalog/MC221"
      expect(page).to have_field "ask_a_question_form_title", visible: false, type: :hidden, with: "Harold B. Hoskins Papers, 1822-1982"
    end

    it "has a suggest a correction form", js: false do
      expect(page).to have_selector "#correction-button"
      expect(page).to have_field "suggest_a_correction_form_context", visible: false, type: :hidden, with: "http://www.example.com/catalog/MC221"
      expect(page).to have_field "suggest_a_correction_form_location_code", visible: false, type: :hidden, with: "publicpolicy"
    end

    it "has overview and abstract summary sections", js: false do
      expect(page).to have_css(".blacklight-creators_ssim a", text: "Hoskins")
      expect(page).to have_css("dd.blacklight-title_ssm", text: "Harold B. Hoskins Papers")
      expect(page).to have_css("dd.blacklight-normalized_date_ssm", text: "1822-1982")
      expect(page).to have_css("dd.blacklight-extent_ssm", text: "17 boxes")
      expect(page).to have_text("Harold Boies Hoskins was a businessman")
      expect(page).to have_css("dd.blacklight-ark_tsim", text: "http://arks.princeton.edu/ark:/88435/q524jn80g")
      expect(page).to have_link("http://arks.princeton.edu/ark:/88435/q524jn80g", href: "http://arks.princeton.edu/ark:/88435/q524jn80g")
    end
    it "has a language property in the overview summary section" do
      expect(page).to have_css("dd.blacklight-language_ssm", text: "English")
    end

    it "has description and creator biography metadata" do
      expect(page.body).to include "This collection consists of correspondence, diaries, notes, photographs,"
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
      expect(page.body).to include "Topics"
      expect(page.body).to include "20th century"
      expect(page.body).to include "Subject Terms"
      expect(page.body).to include "Missionaries"
      expect(page.body).to include "Genre Terms"
      expect(page.body).to include "Correspondence"
      expect(page.body).to include "Names"
      expect(page.body).to include "Foreign Service Institute"
      expect(page.body).to include "Places"
      expect(page.body).to include "Middle East -- Politics"
    end
  end
  context "when a component has a digital object with a manifest" do
    before do
      visit "/catalog/MC221_c0094"
    end

    it "renders the universal viewer" do
      manifest_url = "https://figgy.princeton.edu/concern/scanned_resources/3359153c-82da-4078-ae51-e301f4c5e38b/manifest"
      iframe = "<iframe src=\"https://figgy.princeton.edu/viewer#?manifest=#{manifest_url}\" allowfullscreen=\"true\"></iframe>"
      expect(page.body).to include iframe
    end
  end
  context "when a component has a digital object with a link" do
    before do
      visit "/catalog/MC148_c07608"
    end

    it "renders a view content link" do
      url = "https://webspace.princeton.edu/users/mudd/Digitization/MC148/MC148_c07608.pdf"
      expect(page).to have_selector("a[href=\"#{url}\"]", text: "View Content")
    end

    it "does not render a div for loading from figgy" do
      expect(page).not_to have_selector("#readingroom")
    end
  end

  context "when a component has a digital object with a relative pdf link" do
    before do
      visit "/catalog/C1491_c363"
    end

    it "does not render a view content link" do
      expect(page).not_to have_selector("a[href=\"pdf/c363.pdf", text: "View Content")
    end
  end

  context "when a component has a Physical Description" do
    before do
      visit "/catalog/C1491_c5239"
    end

    it "renders it with the right label" do
      expect(page.body).to include "Physical Description"
      expect(page.body).to include "10 audio cassettes"
    end
  end

  describe "notes", js: false do
    context "on a collection page" do
      it "shows note" do
        visit "/catalog/C0841"

        within("#description") do
          expect(page).to have_selector "dt.blacklight-odd_ssm", text: "Note"
          expect(page).to have_selector "dd.blacklight-odd_ssm", text: /Location of Printed Books Removed for Cataloging/
          expect(page).to have_selector "dd.blacklight-collection_bioghist_ssm", text: /Noël Riley Fitch was born on December 24, 1937/
        end
      end
      it "shows all the relevant notes" do
        visit "/catalog/MC148"

        within("#summary") do
          # Repository
          expect(page).to have_selector "dt.blacklight-repository_ssm", text: "Repository"
          expect(page).to have_selector "dd.blacklight-repository_ssm", text: "Public Policy Papers"
        end

        # Collection Description
        within("#description") do
          # Description
          expect(page).to have_selector "dt.blacklight-collection_description_ssm", text: "Description"
          expect(page).to have_selector "dd.blacklight-collection_description_ssm", text: /This collection consists of the papers of Lilienthal/
          # Arrangement
          expect(page).to have_selector "dt.blacklight-arrangement_ssm", text: "Arrangement"
          expect(page).to have_selector "dd.blacklight-arrangement_ssm", text: /may have been put in this order by Lilienthal/
        end

        # Access
        within("#access") do
          # Access Restrictions
          expect(page).to have_selector "dt.blacklight-accessrestrict_ssm", text: "Access Restrictions"
          expect(page).to have_selector "dd.blacklight-accessrestrict_ssm", text: /Collection is open for research use./
          # Use Restrictions
          expect(page).to have_selector "dt.blacklight-userestrict_ssm", text: "Conditions for Reproduction and Use"
          expect(page).to have_selector "dd.blacklight-userestrict_ssm", text: /Single photocopies/
          # Special Requirements
          expect(page).to have_selector "dt.blacklight-phystech_ssm", text: "Special Requirements for Access"
          expect(page).to have_selector "dd.blacklight-phystech_ssm", text: /Access to audiovisual material/
          # Citation Note
          expect(page).to have_selector "dd.blacklight-prefercite_ssm", text: /David E. Lilienthal Papers;/
          expect(page).not_to have_content "Identification of specific item;"
        end

        # Collection History
        within("#collection-history") do
          # Acquisition
          expect(page).to have_selector "dt.blacklight-acqinfo_ssm", text: "Acquisition"
          expect(page).to have_selector "dd.blacklight-acqinfo_ssm", text: /gift from David E. Lilienthal/
          # Appraisal
          expect(page).to have_selector "dt.blacklight-appraisal_ssm", text: "Archival Appraisal Information"
          expect(page).to have_selector "dd.blacklight-appraisal_ssm", text: /No information about appraisal/
          # Processing Information
          expect(page).to have_selector "dt.blacklight-processinfo_processing_ssm", text: "Processing Information"
          expect(page).to have_selector "dd.blacklight-processinfo_processing_ssm", text: /There is no processing information available for this collection./
        end
        within("#find-more") do
          # Ensure blank labels aren't showing up.
          expect(page).not_to have_selector "dt.blacklight-separatedmaterial_ssm"
          # Subject - include occupation.
          expect(page).to have_selector "dt.blacklight-subject_terms_ssim"
          expect(page).to have_selector "dd.blacklight-subject_terms_ssim", text: /Industries -- Power supply -- United States -- 20th century./
          expect(page).to have_selector "dd.blacklight-subject_terms_ssim", text: /Lawyers -- United States -- 20th century./
          expect(page).to have_selector "dt.blacklight-topics_ssim"
          expect(page).to have_selector "dd.blacklight-topics_ssim", text: /American politics and government/
          expect(page).to have_selector "dt.blacklight-genreform_ssim"
          expect(page).to have_selector "dd.blacklight-genreform_ssim", text: /Audio tapes/
        end
      end
      it "shows separatedmaterial" do
        visit "/catalog/C1210"

        within("#find-more") do
          # Separated Material
          expect(page).to have_selector "dt.blacklight-separatedmaterial_ssm", text: "Separated Material"
          expect(page).to have_selector "dd.blacklight-separatedmaterial_ssm", text: /During 2017 processing/
        end
      end
      it "shows conservation info" do
        visit "/catalog/C1513"
        within("#collection-history") do
          # Conservation
          expect(page).to have_selector "dt.blacklight-processinfo_conservation_ssm", text: "Conservation"
          expect(page).to have_selector "dd.blacklight-processinfo_conservation_ssm", text: /were digitized in 2017./
        end
      end
      it "shows accruals, sponsor" do
        visit "/catalog/C0257"
        # Collection History
        within("#collection-history") do
          # Accruals
          expect(page).to have_selector "dt.blacklight-accruals_ssm", text: "Additions"
          expect(page).to have_selector "dd.blacklight-accruals_ssm", text: /No accruals are expected./
          # Sponsor
          expect(page).to have_selector "dt.blacklight-sponsor_ssm", text: "Sponsor"
          expect(page).to have_selector "dd.blacklight-sponsor_ssm", text: /New Jersey Historical Commission/
        end
      end
      it "shows Creator" do
        visit "/catalog/C1408"
        within("#summary") do
          expect(page).to have_selector "dt.blacklight-creators_ssim", text: "Creator"
          expect(page).to have_selector "dd.blacklight-creators_ssim", text: "Alaveras, Tēlemachos"
        end

        visit "/catalog/C1408_c3"
        within("#component-summary") do
          expect(page).to have_selector "dt.blacklight-collection_creator_ssm", text: "Collection Creator"
          expect(page).to have_selector "dd.blacklight-collection_creator_ssm", text: "Alaveras, Tēlemachos"
        end
      end
      it "shows originalsloc" do
        visit "/catalog/C0274"
        within("#find-more") do
          expect(page).to have_selector "dt.blacklight-originalsloc_ssm", text: "Location of Originals"
          expect(page).to have_selector "dd.blacklight-originalsloc_ssm", text: /One box of the collection consists entirely of photocopies/
        end
      end
      it "shows alternate form available" do
        visit "/catalog/WC064"
        # Find Related Materials
        within("#find-more") do
          # Alternative Form Available
          expect(page).to have_selector "dt.blacklight-altformavail_ssm", text: "Alternative Form Available"
          expect(page).to have_selector "dd.blacklight-altformavail_ssm", text: /Many of the items in this collection/
        end
      end
      it "shows custodial history" do
        visit "/catalog/MC221"
        # Collection History
        within("#collection-history") do
          # Custodial History
          expect(page).to have_selector "dt.blacklight-custodhist_ssm", text: "Custodial History"
          expect(page).to have_selector "dd.blacklight-custodhist_ssm", text: /Gifted to the American Heritage Center/
        end
      end
      it "shows otherfindaid, related materials" do
        visit "/catalog/MC001-02-06"
        # Access Restrictions
        within("#access") do
          expect(page).to have_selector "dt.blacklight-otherfindaid_ssm", text: "Other Finding Aids"
          expect(page).to have_selector "dd.blacklight-otherfindaid_ssm", text: /This finding aid describes a portion/
        end
        # Find Related Materials
        within("#find-more") do
          # relatedmaterial
          expect(page).to have_selector "dt.blacklight-relatedmaterial_ssm", text: "Related Material"
          expect(page).to have_selector "dd.blacklight-relatedmaterial_ssm", text: /American Civil Liberties Union, Washington, D.C. Office Records/
          # Bibliography
          expect(page).to have_selector "dt.blacklight-bibliography_ssm", text: "Publication Note"
          expect(page).to have_selector "dd.blacklight-bibliography_ssm", text: /Historical sketch based on/
        end
      end
      it "shows HTML in the accessrestrict field" do
        visit "/catalog/AC198"

        expect(page).to have_link "University Archives Access Policy"

        visit "/catalog/AC317_c36874-31598"
        expect(page).to have_link "policy on digitization of photographs"
      end
    end
  end

  describe "child component table", js: true do
    it "displays for a collection" do
      visit "/catalog/C1491"

      within(".child-component-table") do
        expect(page).to have_link "Writings"
        expect(page).to have_content "1917-2017 April 11"
      end
    end
    it "displays for every resource" do
      visit "/catalog/C1491_c3"

      within(".child-component-table") do
        expect(page).to have_link "Outlines and Notes"
        expect(page).to have_content "Box 1, Folder 1"
        expect(page).to have_content "undated"
        expect(page).to have_button "add-to-cart-button_C1491_c4"
        click_button "add-to-cart-button_C1491_c4"
      end

      expect(page).to have_button "Request 1 Item"
    end
  end

  context "when a component has a unit ID", js: false do
    it "displays it" do
      visit "/catalog/AC362_c01738"

      expect(page).to have_content "1032"
      expect(page).to have_content "Item Number"
    end
  end

  describe "collection bioghist notes", js: true do
    it "displays for a collection" do
      visit "/catalog/C0292"
      find("#description-tab a").click

      expect(page).to have_selector "dt.blacklight-collection_bioghist_ssm"
      expect(page).to have_content("Collection Creator Biography:")

      expect(page).to have_selector "dd.blacklight-collection_bioghist_ssm"

      expect(page).to have_selector "dd.blacklight-collection_bioghist_ssm p.personal-name", text: "Thorp, Margaret Farrand, 1891-1970"
      expect(page).to have_selector "dd.blacklight-collection_bioghist_ssm p.head", text: "Biographical / Historical"
      expect(page).to have_content("Margaret Louise Farrand Thorp (1891-1970), scholar, author, critic, and journalist, was born in East Orange, New Jersey, on December 3, 1891.")

      expect(page).to have_selector "dd.blacklight-collection_bioghist_ssm hr"
      expect(page).to have_selector "dd.blacklight-collection_bioghist_ssm p.personal-name", text: "Thorp, Willard, 1899-1990"
      expect(page).to have_content("William Willard Thorp (1899-1990), literary historian, editor, educator, author, and critic, was born on April 20 in Sydney, New York.")
    end
  end
end
