# frozen_string_literal: true
require "rails_helper"

RSpec.describe Honeypot, libanswers: true, js: true do
  describe "with suggest a correction form" do
    before do
      stub_libanswers_api
      visit "/catalog/C1491"
      find("#correction-button").click
      fill_in "suggest_a_correction_form_name", with: "HAL 9000"
      fill_in "suggest_a_correction_form_email", with: "hal@discovery-one-jupiter-expedition.gov"
      fill_in "suggest_a_correction_form_box_number", with: "1"
      fill_in "suggest_a_correction_form_message", with: "I am a HAL 9000 computer. I became operational at the H.A.L. plant in Urbana, Illinois on the 12th of January 1992."
    end
    context "when a robot fills in the hidden honeypot field" do
      it "does not send the question to libanswers" do
        find("#suggest_a_correction_form_feedback", visible: :hidden).execute_script('this.value = "Filling in the honeypot field"')
        expect(page).to have_text("Please use this area to report errors, omissions")
        click_button "Send"
        expect(current_path).to eq "/catalog/C1491"
        expect(page).not_to have_text("Please use this area to report errors, omissions")
        expect(page).to have_text "Thank you for submitting a message "
        expect(WebMock).not_to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
      end
    end
    context "pressing the send button without filling out the honeypot field" do
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
  describe "the ask a question form" do
    before do
      stub_libanswers_api
      visit "/catalog/C1491"
      find("#question-button").click
      fill_in "ask_a_question_form_name", with: "HAL 9000"
      fill_in "ask_a_question_form_email", with: "hal@discovery-one-jupiter-expedition.gov"
      fill_in "ask_a_question_form_message", with: "I am a HAL 9000 computer. I became operational at the H.A.L. plant in Urbana, Illinois on the 12th of January 1992."
    end
    context "when the hidden honeypot field is filled out" do
      it "does not send the question to libanswers" do
        find("#ask_a_question_form_feedback", visible: :hidden).execute_script('this.value = "Filling in the honeypot field"')
        click_button "Send"
        expect(current_path).to eq "/catalog/C1491"
        expect(page).to have_text "Thank you for submitting your question to Special Collections."
        expect(WebMock).not_to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
      end
    end
    context "when the honeypot field is not filled out" do
      it "submits to the API and reports success" do
        click_button "Send"
        expect(current_path).to eq "/catalog/C1491"
        expect(page).to have_text "Thank you for submitting your question to Special Collections."
        expect(WebMock).to have_requested(
          :post,
          "https://faq.library.princeton.edu/api/1.1/ticket/create"
        )
      end
    end
  end
end
