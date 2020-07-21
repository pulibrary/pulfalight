# frozen_string_literal: true

require "rails_helper"

describe "viewing catalog records", type: :feature, js: true do
  context "when viewing a component which can be requested from Aeon" do
    before do
      visit "/catalog/MC148_c00001"
    end

    it "renders a request button" do
      expect(page).to have_css(".al-request-button")
    end

    it "generates a request <form>" do
      expect(page).to have_css(".al-request-form")
      expect(page).to have_css(".al-request-form input[name='Request']", visible: false)
      expect(page).to have_css(".al-request-form input[name='Notes']", visible: false)
      expect(page).to have_css(".al-request-form input[name='scheduledDate']", visible: false)
      expect(page).to have_css(".al-request-form input[name='AeonForm']", visible: false)
      expect(page).to have_css(".al-request-form input[name='RequestType']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingIdentifier']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_ReferenceNumber']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_ItemNumber']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_ItemDate']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_CallNumber']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_ItemVolume']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_ItemInfo1']", visible: false)
      expect(page).to have_css(".al-request-form input[name='GroupingOption_Location']", visible: false)
      expect(page).to have_css(".al-request-form input[name='ItemTitle[]']", visible: false)

      expect(page).to have_css(".al-request-form input[name^='CallNumber_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemTitle_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemAuthor_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemDate_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemNumber_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemInfo1_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemInfo2_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemInfo3_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemInfo4_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ItemInfo5_']", visible: false)
      expect(page).to have_css(".al-request-form input[name^='ReferenceNumber_']", visible: false)

      expect(page).to have_css(".al-request-form input[name='DocumentType']", visible: false)
      expect(page).to have_css(".al-request-form input[name='Site']", visible: false)
      expect(page).to have_css(".al-request-form input[name='SubmitButton']", visible: false)
    end
  end
end
