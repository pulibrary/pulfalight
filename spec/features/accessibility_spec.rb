# frozen_string_literal: true

require "rails_helper"

describe "accessibility", type: :feature, js: true do
  context "home page" do
    it "complies with WCAG" do
      stub_lib_cal(id: "14275")
      stub_lib_cal(id: "12315")

      visit "/"

      expect(page).to be_axe_clean.according_to :wcag2a, :wcag2aa, :wcag21a, :wcag21aa
    end
  end
end
