# frozen_string_literal: true
require "rails_helper"

RSpec.describe PartnerExportsController do
  describe "#pacscl" do
    it "outputs links to every finding aid's XML without containers" do
      get "/pacscl/production"

      expect(response.body).to have_selector("#links a")
      expect(response.body).to have_link("Toni Morrison Papers, 1908-2017 (mostly 1970-2015)", href: "/pacscl/production/C1491.xml")
    end
  end

  describe "#pacscl_xml" do
    it "returns XML without containers, and with correct repository names" do
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
      expect(doc.xpath("//repository/corpname").first.text).to eq "Princeton University Library: Manuscripts Division"
    end

    context "when the requested component does not exist" do
      it "logs an error and returns a 404" do
        ead = Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "WC064.processed.EAD.xml").open
        client = instance_double(Aspace::Client, get_xml: ead)
        allow(Aspace::Client).to receive(:new).and_return(client)
        allow(Rails.logger).to receive(:warn)

        expect { get("/pacscl/production/WC064_not_a_component.xml") }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with(/Error generating xml/)
        expect(response.status).to eq 404
      end
    end

    context "when there is a connection issue with ArchiveSpace" do
      it "logs an error and returns a 500" do
        client = instance_double(Aspace::Client)
        allow(Aspace::Client).to receive(:new).and_return(client)
        allow(client).to receive(:get_xml).and_raise(ArchivesSpace::ConnectionError.new("can't connect"))
        allow(Rails.logger).to receive(:warn)

        expect { get("/pacscl/production/AC500_c23929-57796.xml") }.not_to raise_error
        expect(Rails.logger).to have_received(:warn).with("ArchivesSpace::ConnectionError: can't connect")
        expect(response.status).to eq 500
      end
    end
  end
end
