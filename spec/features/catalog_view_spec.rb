# frozen_string_literal: true

require "rails_helper"

describe "viewing catalog records", type: :feature, js: true do
  context "when viewing a component show page" do
    it "renders a collection title without a separate date element" do
      visit "catalog/MC221_c0059"
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
end
