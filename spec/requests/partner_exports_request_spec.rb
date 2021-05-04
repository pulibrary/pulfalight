# frozen_string_literal: true
require "rails_helper"

RSpec.describe PartnerExportsController do
  describe "#pacscl" do
    it "outputs links to every finding aid's XML without containers" do
      get "/pacscl/production"

      expect(response.body).to have_selector("#links a", count: 32)
      expect(response.body).to have_link("Toni Morrison Papers, 1908-2017, bulk 1970/2015", href: "/catalog/C1491.xml?containers=false")
    end
  end
end
