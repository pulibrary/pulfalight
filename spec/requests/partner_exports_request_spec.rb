# frozen_string_literal: true
require "rails_helper"

RSpec.describe PartnerExportsController do
  describe "#pacscl" do
    it "outputs links to every finding aid's XML without containers" do
      get "/pacscl/production"

      expect(response.body).to have_selector("#links a", count: 32)
      expect(response.body).to have_link("Toni Morrison Papers, 1908-2017, bulk 1970/2015", href: "/pacscl/production/C1491.xml")
    end
  end

  describe "#pacscl_redirect" do
    it "redirects to the XML without containers" do
      get "/pacscl/production/C1491.xml"

      expect(response).to redirect_to "/catalog/C1491.xml?containers=false"
    end
  end
end
