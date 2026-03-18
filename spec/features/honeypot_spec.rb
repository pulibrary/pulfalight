# frozen_string_literal: true
require "rails_helper"

RSpec.describe SuggestACorrectionForm, libanswers: true, js: true do
  describe "with suggest a correction form" do 
    context "when a robot fills in the hidden honeypot field" do
      before do
        stub_libanswers_api
        visit "/catalog/C1491"
        find("#correction-button").click
        fill_in "suggest_a_correction_form_name", with: "HAL 9000"
        fill_in "suggest_a_correction_form_email", with: "hal@discovery-one-jupiter-expedition.gov"
        fill_in "suggest_a_correction_form_box_number", with: "1"
        fill_in "suggest_a_correction_form_message", with: "I am a HAL 9000 computer. I became operational at the H.A.L. plant in Urbana, Illinois on the 12th of January 1992."
        find("#suggest_a_correction_form_feedback", visible: :hidden).execute_script('this.value = "Filling in the honeypot field"')
      end
      it "does not send the question to libanswers" do
        expect(page).to have_text("Please use this area to report errors, omissions")
        click_button "Send"
        expect(current_path).to eq "/catalog/C1491"
        expect(page).not_to have_text("Please use this area to report errors, omissions")
        expect(WebMock).not_to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
      end
      it "does report success on submission" do
        expect(page).to have_text("Please use this area to report errors, omissions")
        click_button "Send"
        expect(page).to have_text "Thank you for submitting a message "
      end
    end
    describe "pressing the send button without filling out the honeypot field" do
      before do
        stub_libanswers_api
        visit "/catalog/C1491"
        find("#correction-button").click
        fill_in "suggest_a_correction_form_name", with: "Hercule Poirot"
        fill_in "suggest_a_correction_form_email", with: "herpo@poi.her"
        fill_in "suggest_a_correction_form_box_number", with: "1"
        fill_in "suggest_a_correction_form_message", with: "Death on the Nile"
      end
      it "reports success" do
        expect(page).to have_text("Please use this area to report errors, omissions")
        click_button "Send"
        expect(current_path).to eq "/catalog/C1491"
        expect(page).not_to have_text("Please use this area to report errors, omissions")
        expect(WebMock).to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
        expect(page).to have_text "Thank you for submitting a message "
      end
    end
  end
end
