# frozen_string_literal: true
require "rails_helper"

describe "controller requests", type: :request do
  describe "/catalog/:id/raw" do
    it "renders a raw Solr JSON document" do
      get "/catalog/WC064/raw"
      expect(response.body).not_to be_empty
      json_body = JSON.parse(response.body)
      expect(json_body).to include("id" => "WC064")
      expect(json_body).to include("title_ssm" => ["Princeton University Library Collection of Western Americana Photographs"])
    end
  end

  describe "/catalog/:id XML" do
    context "for a collection" do
      it "returns the full finding aid from ASpace" do
        login_stub = stub_aspace_login
        stub_aspace_repositories
        search_stub = stub_search(repository_id: "13", resource_ids: ["WC064"]).last
        ead_stub = stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/WC064", ead: "generated/mss/WC064.processed.EAD.xml")

        get "/catalog/WC064.xml"

        expect(response).to be_successful
        doc = Nokogiri::XML.parse(response.body)
        doc.remove_namespaces!
        expect(doc.xpath("//eadid").first.text).to eq "WC064"
        expect(doc.xpath("//c").first["id"]).to eq "WC064_c1"

        # Ensure caching is working
        get "/catalog/WC064.xml"
        expect(login_stub).to have_been_requested.once
        expect(ead_stub).to have_been_requested.once
        expect(search_stub).to have_been_requested.once
      end
      it "works with caching for periods" do
        stub_aspace_login
        stub_aspace_repositories
        search_stub = stub_search(repository_id: "13", resource_ids: ["C0744.03"]).last
        ead_stub = stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/C0744.03", ead: "generated/mss/C0744.03.processed.EAD.xml")

        get "/catalog/C0744-03.xml"

        expect(response).to be_successful
        doc = Nokogiri::XML.parse(response.body)
        doc.remove_namespaces!
        expect(doc.xpath("//eadid").first.text).to eq "C0744.03"

        # Ensure caching is working
        get "/catalog/C0744-03.xml"
        expect(ead_stub).to have_been_requested.once
        expect(search_stub).to have_been_requested.once
      end

      it "works when the id has a dash but the ref has a dot" do
        stub_aspace_login
        stub_aspace_repositories
        stub_search(repository_id: "13", resource_ids: ["AC198.10"]).last
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/AC198.10", ead: "generated/univarchives/AC198.10.processed.EAD.xml")

        get "/catalog/AC198-10_c6.xml"

        expect(response).to be_successful
      end
      it "can be requested to not include containers" do
        stub_aspace_login
        stub_aspace_repositories
        stub_search(repository_id: "13", resource_ids: ["WC064"]).last
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/WC064", ead: "generated/mss/WC064.processed.EAD.xml")

        get "/catalog/WC064.xml?containers=false"

        expect(response).to be_successful
        doc = Nokogiri::XML.parse(response.body)
        doc.remove_namespaces!
        expect(doc.xpath("//eadid").first.text).to eq "WC064"
        expect(doc.xpath("//c").first["id"]).to eq "WC064_c1"
        expect(doc.xpath("//container").length).to eq 0
      end
    end
    context "for a component" do
      it "shows the component XML" do
        stub_aspace_login
        stub_aspace_repositories
        search_stub = stub_search(repository_id: "13", resource_ids: ["WC064"]).last
        ead_stub = stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/WC064", ead: "generated/mss/WC064.processed.EAD.xml")

        get "/catalog/WC064_c1.xml"

        expect(response).to be_successful
        doc = Nokogiri::XML.parse(response.body)
        expect(doc.children[0]["id"]).to eq "WC064_c1"

        # Ensure caching is working
        get "/catalog/WC064_c1.xml"
        expect(ead_stub).to have_been_requested.once
        expect(search_stub).to have_been_requested.once
      end
    end

    context "for a component EAD with namespaced elements" do
      it "shows the component XML with namespaces removed" do
        stub_aspace_login
        stub_aspace_repositories
        stub_search(repository_id: "13", resource_ids: ["C1491"]).last
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/C1491", ead: "generated/mss/C1491.processed.EAD.xml")

        get "/catalog/C1491_c4.xml"

        doc = Nokogiri::XML.parse(response.body)
        expect(doc.children[0]["id"]).to eq "C1491_c4"
        expect(response.body).not_to include("xlink:title")
      end
    end
  end

  describe "/catalog/:id JSON" do
    context "for a component" do
      it "renders sufficient JSON for Figgy to use" do
        get "/catalog/WC064_c1.json"
        json_body = JSON.parse(response.body)

        expect(json_body["title"]).to eq ["American Indian man wearing traditional clothing with three white children"]
        expect(json_body["language"]).to eq ["English"]
        expect(json_body["date_created"]).to eq ["1850-1860"]
        expect(json_body["created"]).to eq ["1850-1860"]
        expect(json_body["extent"]).to eq ["1 folder; 10 x 7 cm."]
        expect(json_body["container"]).to eq ["Box h1, Folder h0001"]
        expect(json_body["heldBy"]).to eq ["Firestone Library"]
        expect(json_body["creator"]).to be_nil
        expect(json_body["publisher"]).to eq ["Princeton University. Library. Special Collections"]
        expect(json_body["memberOf"]).to eq [
          {
            "title" => "Princeton University Library Collection of Western Americana Photographs, 1840-1998 (mostly 1870-1915)",
            "identifier" => "WC064"
          }
        ]
      end
      it "renders just the location code if it can't find a string" do
        allow(Pulfalight::LocationCode).to receive(:registered?).and_return(false)
        get "/catalog/WC064_c1.json"
        json_body = JSON.parse(response.body)

        expect(json_body["heldBy"]).to eq ["mss"]
      end
    end
    context "with a component with a content warning" do
      it "renders it" do
        get "/catalog/C1372_c47202-68234.json"

        json_body = JSON.parse(response.body)
        expect(json_body["content_warning"]).to eq ['The "Revolution in China" album contains photographs of dead bodies.']
      end
      it "doesn't render it for content warnings inherited from the series" do
        get "/catalog/TC040_c00034.json"
        json_body = JSON.parse(response.body)

        expect(json_body["content_warning"]).to be_blank
      end
    end
    context "for a collection" do
      it "renders sufficient JSON for Figgy to use" do
        get "/catalog/WC064.json"
        json_body = JSON.parse(response.body)

        expect(json_body["title"]).to eq ["Princeton University Library Collection of Western Americana Photographs"]
        expect(json_body["language"]).to eq ["English"]
        expect(json_body["date_created"]).to eq ["1840-1998 (mostly 1870-1915)"]
        expect(json_body["created"]).to eq ["1840-1998"]
        expect(json_body["extent"]).to eq ["144 boxes", "123 linear feet"]
        expect(json_body["heldBy"]).to eq ["Firestone Library"]
        expect(json_body["memberOf"]).to be_nil
      end
    end
  end
end
