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
    it "renders component-level notes" do
      get "/catalog/C1619_c24"

      expect(response.body).to include "This file group includes drafts"
      get "/catalog/C0033_c001"
      expect(response.body).to include "Chabert, Marie Claire, 1769-1847"
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
    xit "renders the notes on the collection show page" do
      # TODO: Remove collection notes and index more fine-grained metadata on the description and history tabs
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
    it "returns results as if you didn't search with quotes" do
      get "/catalog", params: { q: "Marie Claire Chabert", search_field: "all_fields" }
      no_quote_results = assigns.fetch(:document_list).map(&:id)

      get "/catalog", params: { q: '"Marie Claire Chabert"', search_field: "all_fields" }

      expect(assigns.fetch(:document_list).map(&:id)).to eq no_quote_results
    end
  end
end
