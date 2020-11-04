# frozen_string_literal: true

require "rails_helper"

describe "the home page", type: :feature, js: true do
  it "is accessible" do
    stub_lib_cal(id: "14275")
    stub_lib_cal(id: "12315")

    visit "/"

    expect(page).to be_axe_clean
  end
end
