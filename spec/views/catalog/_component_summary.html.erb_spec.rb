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
end
