# frozen_string_literal: true

require "rails_helper"

describe "the catalog view request cart", type: :feature, js: true do
  context "when viewing a component which can be requested from Aeon" do
    it "adds the item to and removes it from the cart" do
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

  context "when using the application in multiple tabs" do
    it "adds the item to the cart in all tabs, but each tab controls the cart's visibility independently" do
      visit "/catalog/MC148_c00002"

      new_tab = window_opened_by do
        page.execute_script('window.open("/catalog/MC148", "_blank");')
      end
      within_window new_tab do
        expect(page).to have_selector "#count", text: "0"
      end

      find(".add-to-cart-block").click
      within(".request-cart") do
        expect(page).to have_selector "#item-MC148_c00002"
      end

      # the icon count has incremented, but the cart modal didn't open
      within_window new_tab do
        expect(page).to have_selector "#count", text: "1"
        expect(page).not_to have_selector ".request-cart"
        # open it and click remove
        find(".cart-view-toggle-block > div > button").click
        within(".request-cart") do
          find("#item-MC148_c00002 > td > button").click
        end
      end

      # on the original page, the item is no longer in the cart but the cart is
      # still open
      expect(page).to have_selector ".request-cart"
      within(".request-cart") do
        expect(page).not_to have_selector "#item-MC148_c00002"
        expect(page).to have_selector "button[type='submit']", text: /No Items in Your Cart/
      end
    end
  end
end
