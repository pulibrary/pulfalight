# frozen_string_literal: true
require "rails_helper"

RSpec.describe PartnerExportsController do
  describe "#pacscl" do
    it "outputs links to every finding aid's XML without containers" do
      get "/pacscl/production"

      expect(response.body).to have_selector("#links a", count: 36)
      expect(response.body).to have_link("Toni Morrison Papers, 1908-2017, bulk 1970/2015", href: "/pacscl/production/C1491.xml")
    end
  end

  describe "#pacscl_xml" do
    it "returns XML without containers" do
      stub_aspace_login
      stub_aspace_repositories
      stub_search(repository_id: "13", resource_ids: ["WC064"]).last
      stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/WC064", ead: "generated/mss/WC064.processed.EAD.xml")

      get "/pacscl/production/WC064.xml"

      expect(response).to be_successful
      doc = Nokogiri::XML.parse(response.body)
      doc.remove_namespaces!
      expect(doc.xpath("//eadid").first.text).to eq "WC064"
      expect(doc.xpath("//c").first["id"]).to eq "WC064_c1"
      expect(doc.xpath("//container").length).to eq 0
    end
  end
end
