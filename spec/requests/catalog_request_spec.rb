# frozen_string_literal: true
require "rails_helper"

describe "controller requests", type: :request do
  context "on the home page" do
    it "displays a large-form header and search bar" do
      get "/"
      expect(response.body).to have_selector ".home-header"
      expect(response.body).not_to have_field "search_field"
    end
  end
  context "when requesting to view a component" do
    it "renders containers within component" do
      get "/catalog/C1588_c15"
      expect(response).to render_template(:show)
      expect(response.body).to include("Folder 11")
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

  context "when an AJAX request is transmitted for a collection document" do
    it "renders a minimal HTML template in the response" do
      get("/catalog/WC064", xhr: true)

      expect(response.body).to include("<div id=\"document-minimal-WC064\"")
      html_tree = Nokogiri::HTML(response.body)
      field_name_elements = html_tree.css("#document-minimal-WC064 .document-minimal-field-name")
      expect(field_name_elements).not_to be_empty
      first_field_element = field_name_elements.first
      expect(first_field_element.text).to eq "id"
      second_field_element = field_name_elements[1]
      expect(second_field_element.text).to eq "has_digital_content"

      field_value_elements = html_tree.css("#document-minimal-WC064 .document-minimal-field-value")
      expect(field_value_elements).not_to be_empty
      first_field_element = field_value_elements.first
      expect(first_field_element.text).to eq "WC064"
      second_field_element = field_value_elements[1]
      expect(second_field_element.text).to eq "true"

      component_field_elements = field_name_elements.select { |element| element.text == "components" }
      expect(component_field_elements).not_to be_empty
      component_field_element = component_field_elements.first
      component_tree_element = component_field_element.parent
      child_component_elements = component_tree_element.css("#document-minimal-aspace_WC064_c1")
      expect(child_component_elements).not_to be_empty
    end

    context "when requesting a component with child component nodes" do
      it "renders a minimal HTML template in the response without child components" do
        get("/catalog/WC064", xhr: true)

        expect(response.body).to include("<div id=\"document-minimal-WC064\"")
        html_tree = Nokogiri::HTML(response.body)
        field_name_elements = html_tree.css("#document-minimal-WC064 .document-minimal-field-name")
        expect(field_name_elements).not_to be_empty

        component_field_elements = field_name_elements.select { |element| element.text == "components" }
        expect(component_field_elements).not_to be_empty
        component_field_element = component_field_elements.first
        component_tree_element = component_field_element.parent
        child_component_elements = component_tree_element.css(".document-minimal-field-value")
        expect(child_component_elements).not_to be_empty
        expect(child_component_elements.first.text).to eq("aspace_WC064_c1")
      end
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
      expect(response.body).to include("PREFERRED CITATION:")
      expect(response.body).to include("Harold B. Hoskins Papers; Public Policy Papers, Department of Special Collections, Princeton University Library")
    end
  end

  describe "searching all collections" do
    context "when searching for a specific collection by ID" do
      it "directs the user to the exact collection if it exists" do
        get "/catalog?q=WC064"
        expect(response).to redirect_to("http://www.example.com/catalog/WC064")
      end

      it "directs the user to the search results if it does not exist" do
        get "/catalog?q=WC063"
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
  end
end
