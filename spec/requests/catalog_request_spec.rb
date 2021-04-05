# frozen_string_literal: true
require "rails_helper"

describe "controller requests", type: :request do
  context "on the home page" do
    it "displays a large-form header, search bar, and request cart" do
      get "/"
      expect(response.body).to have_selector ".home-header"
      expect(response.body).not_to have_field "search_field"
      expect(response.body).to have_selector "cart-view-toggle"
      expect(response.body).to have_selector ".request-cart-block request-cart"
    end
  end
  context "when requesting to view a component", js: false do
    it "renders containers within component" do
      get "/catalog/C1588_c15"
      expect(response).to render_template(:show)
      expect(response.body).to include("Folder 11")
    end
    it "renders a component with diacritics" do
      get "/catalog/C1408"
      expect(response.body).to include("Tēlemachos")
      expect(response.body).to include("Thessalonikē")
    end
    it "renders component-level names" do
      get "/catalog/C0140_c29843-01832"

      expect(response.body).to include "Gallatin, Albert, 1761-1849"
    end
    it "renders component-level notes" do
      get "/catalog/C1619_c24"

      expect(response.body).to include "This file group includes drafts"
      get "/catalog/C0033_c001"
      expect(response.body).to include "Chabert, Marie Claire, 1769-1847"

      get "/catalog/AC187_c00654"
      expect(response.body).to have_selector("#component-summary", text: "[RESTRICTED]")
    end
    it "renders all the appropriate component metadata" do
      get "/catalog/C0140_c03411"

      expect(response.body).to have_selector "dd.blacklight-creator_ssm", text: "Chandler, John Lincoln, 1820–1888"
      expect(response.body).to have_selector "dd.blacklight-collection_creator_ssm", text: "Princeton University. Library. Special Collections"
      expect(response.body).to include("1866 March 7")
      expect(response.body).to include("AM 2021-10")
      # Ensure that acqinfo isn't coming from the collection.
      expect(response.body).not_to have_selector ".overview dd.blacklight-acqinfo_ssm", text: /resulted from miscellaneous/
      expect(response.body).to have_selector "#component-summary a", text: "Tennessee--History--19th century--Sources."
      # Ensure the collection subjects aren't on the component page.
      expect(response.body).not_to have_selector "#component-summary a", text: "Poets."
    end
  end

  context "when requesting a URL from the legacy system" do
    it "redirects requests for '/collections/eadid/componentid' to '/catalog/eadid_componentid'" do
      get "/collections/C0140/c03411"
      expect(response.code).to eq "301"
      expect(response).to redirect_to("http://www.example.com/catalog/C0140_c03411")
    end
    it "redirects requests correctly when there are dots in the eadid" do
      get "/collections/MC001.02.01/c00003"
      expect(response.code).to eq "301"
      expect(response).to redirect_to("http://www.example.com/catalog/MC001-02-01_c00003")
    end
    it "redirects collections too" do
      get "/collections/MC001.02.01"
      expect(response.code).to eq "301"
      expect(response).to redirect_to("http://www.example.com/catalog/MC001-02-01")
    end
  end

  context "when requesting a JSON serialization of the Document" do
    it "generates the JSON object" do
      get("/catalog/WC064", params: { format: :json })
      expect(response.body).not_to be_empty
      json_body = JSON.parse(response.body)
      expect(json_body).to include("id")
      expect(json_body["id"]).to include("WC064")
    end
  end

  context "when requesting a component with child component nodes" do
    before do
      get "/catalog/MC148?expanded=true"
    end

    it "renders the expanded collection view template" do
      html_tree = Nokogiri::HTML(response.body)
      field_name_elements = html_tree.css(".document-title h3")

      expect(field_name_elements).not_to be_empty
      expect(field_name_elements.first.text).to include("Series 1: Articles, books, and Lecture Notes by David E.")
      expect(field_name_elements.last.text).to include("Center of Theological Inquiry, 1978")

      attribute_elements = html_tree.css(".collection-tree-block--child .document-extent")
      expect(attribute_elements).not_to be_empty
      expect(attribute_elements.first.text).to include("17 boxes")
      expect(attribute_elements.last.text).to include("1 box")
    end
  end

  describe "collection-level notes" do
    it "renders the notes on the collection show page" do
      get "/catalog/C1588"
      expect(response.body).to include("Consists primarily of three diaries that William Dundas Bathurst (1859-1940)")
      expect(response.body).to include("No materials were removed from the collection during 2018 processing beyond")
    end
  end

  context "when the collection repository has citation formatting configured" do
    it "renders the preferred citation for the collection" do
      get "/catalog/MC221"
      expect(response).to render_template(:show)
      expect(response.body).to include("Credit this material")
      expect(response.body).to include("Harold B. Hoskins Papers, Box and Folder Number; Public Policy Papers, Special Collections, Princeton University Library.")
    end
  end

  describe "searching all collections" do
    context "when searching for a specific collection by ID" do
      it "directs the user to the exact collection if it exists" do
        get "/catalog?q=WC064"
        expect(response).to redirect_to("http://www.example.com/catalog/WC064")

        get "/catalog?q=MC152"
        expect(response).to redirect_to("http://www.example.com/catalog/MC152")

        get "/catalog?q=mc152"
        expect(response).to redirect_to("http://www.example.com/catalog/MC152")

        get "/catalog?q=MC001.02.06"
        expect(response).to redirect_to("http://www.example.com/catalog/MC001-02-06")
      end

      it "directs the user to the search results if it does not exist" do
        get "/catalog?q=WC063"
        expect(response.body).to include("Search Results")
        expect(response.body).not_to have_selector ".home-header"

        get "/catalog?q=MC128"
        expect(response.body).to include("Search Results")
        expect(response.body).not_to have_selector ".home-header"
      end

      context "when no query is provided" do
        it "directs to the default search page" do
          get "/catalog?q="
          expect(response.body).to include("Location and Today's Hours")
        end
      end
    end

    context "when searching for a specific component by ID" do
      it "directs the user to the exact component if it exists" do
        get "/catalog?q=MC148_c00002"
        expect(response).to redirect_to("http://www.example.com/catalog/MC148_c00002")
      end

      it "directs the user to the search results if it does not exist" do
        get "/catalog?q=MC148_cabc"
        expect(response.body).to include("Search Results")
        expect(response.body).not_to have_selector ".home-header"
      end
    end
  end

  describe "searching for box and folder number", js: false do
    it "returns it" do
      get "/catalog", params: { q: "MC221 Box 1 Folder 4", search_field: "all_fields" }
      expect(assigns.fetch(:document_list, []).map(&:id).first).to eq "MC221_c0004"
    end
  end

  describe "searching for a collection name", js: false do
    it "boosts collections" do
      get "/catalog", params: { q: "Lilienthal", search_field: "all_fields" }
      expect(assigns.fetch(:document_list, []).map(&:id).first).to eq "MC148"
    end
  end

  describe "searching with quotes", js: false do
    it "returns a match for names in the wrong order" do
      get "/catalog", params: { q: '"Frederick Vinton"', search_field: "all_fields" }

      results = assigns.fetch(:document_list).map(&:id)

      expect(results.length).to eq 1
    end
  end

  describe "searching hierarchy", js: false do
    it "returns a match for separate parts in the hierarchy" do
      get "/catalog", params: { q: "wilson suffrage", search_fields: "all_fields" }

      results = assigns.fetch(:document_list).map(&:id)

      expect(results).to include("MC168_c02041")
    end
  end
end
