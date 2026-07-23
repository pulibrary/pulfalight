# frozen_string_literal: true
require "rails_helper"

describe "expanded collection view", type: :feature, js: true do
  it "renders the header and footer" do
    visit "/catalog/MC221?expanded=true"

    expect(page).to have_link("Princeton University Library", href: "https://library.princeton.edu")
    expect(page).to have_link("Accessibility", href: "https://accessibility.princeton.edu/help")
  end

  it "renders the online-material toggle" do
    visit "/catalog/MC221?expanded=true"

    expect(page).to have_css(".toc-online-toggle")
    expect(page).to have_css("#tocOnlineToggle", visible: :all)
  end
end
