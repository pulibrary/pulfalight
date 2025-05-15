# frozen_string_literal: true
require "rails_helper"

describe "catalog/_component_summary" do
  context "when the component does not have an extent" do
    let(:document) do
      {
        "normalized_title_ssm" => ["Princeton Ethiopic Manuscript No. 7: Image of Saint George (Mälkə'a Giyorgis), Image of the Christian Sabbath (Mälkə'a Sänbätä Kərəstiyan), 0-1945"]
      }
    end
    let(:solr_document) { SolrDocument.new(document) }

    it "doesn't render an extent badge" do
      stub_template "catalog/_show_upper_metadata_default" => ""
      assign :document, solr_document
      render

      expect(rendered).not_to have_selector(".document-title .document-extent")
    end
  end
  context "when the component has restricted content" do
    let(:document) do
      {
        "accessrestrict_ssm" => ["This item is restricted. These materials will be available in 2075."],
        "access_ssi" => ["restricted"]
      }
    end
    let(:solr_document) { SolrDocument.new(document) }

    it "displays a warning above the description about restricted materials" do
      stub_template "catalog/_show_upper_metadata_default" => ""
      assign :document, solr_document
      render

      expect(response.body).to have_css(".access-restrictions-warning", text: "This item is restricted.") 
      
    end

    it "truncates long text to 25 characters for the warning" do
      stub_template "catalog/_show_upper_metadata_default" => ""
      assign :document, solr_document
      render

      expect(response.body).to have_css(".access-restrictions-warning", text: /^.{0,25}$/) 
    end

    it "adds a link and modal containing the full text of conditions governing access" do
      stub_template "catalog/_show_upper_metadata_default" => ""
      assign :document, solr_document
      render

      expect(rendered).to have_button "Read full Conditions Governing Access"
      expect(response.body).to have_css(".modal-body", text: "This item is restricted. These materials will be available in 2075.") 
    end
  end
end
