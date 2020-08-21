# frozen_string_literal: true

require "rails_helper"

describe "viewing catalog records", type: :feature, js: true do
  context "when viewing a component which can be requested from Aeon" do
    xit "renders a request button" do
      visit "/catalog/MC148_c00001"

      # This is now blocked by the Request Cart Vue integration
    end

    it "generates a request <form>" do
      # MC148_c00002
      # visit "/catalog/aspace_WC064_c1"
      visit "/catalog/MC148_c00002"

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
