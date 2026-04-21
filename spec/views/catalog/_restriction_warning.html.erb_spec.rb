# frozen_string_literal: true
require "rails_helper"

describe "catalog/_restriction_warning" do
  before(:all) do
    ActionView::TestCase::TestController.include(Arclight::FieldConfigHelpers)
  end

  let(:html_link) do
    '<a href="https://library.princeton.edu/special-collections/policies/' \
      'access-to-restricted-collections">Access to Restricted Collections policy</a>'
  end
  let(:solr_document) do
    SolrDocument.new("id" => "C1491_c1")
  end
  let(:locals) do
    { document: solr_document, field: nil, field_name: "accessrestrict_ssm", metadata: nil, doc_presenter: nil }
  end

  before do
    allow(solr_document).to receive(:field_with_headings).with("accessrestrict_ssm").and_return(headings)
  end

  context "when the restriction text contains HTML and visible text exceeds 300 chars" do
    let(:body) { "Restricted access. " * 20 }
    let(:headings) do
      # As raw html this message has 543 characters.
      # As visible text, the message has 437 characters and will be truncated.
      { "Conditions Governing Access" => ["#{body} See #{html_link} for details."] }
    end

    it "renders a truncated plain-text preview with no escaped HTML" do
      render partial: "catalog/restriction_warning", locals: locals

      expect(rendered).to have_button("Read full Conditions Governing Access")
      expect(rendered).not_to include("&lt;a ")
      expect(rendered).not_to include("<a href=\"https://library.princeton.edu")
    end

    it "shows the full HTML with a working link inside the modal" do
      render partial: "catalog/restriction_warning", locals: locals
      modal = view.content_for(:modals)

      expect(modal).to have_css(
        "#restrictionsModal .modal-body a[href*='access-to-restricted-collections']",
        text: "Access to Restricted Collections policy"
      )
    end
  end

  context "when the visible restriction text is short but contains HTML with a long URL" do
    let(:body) { "Restricted access. " * 10 }
    let(:headings) do
      # As raw html this message has 353 characters.
      # As visible text, the message has 190.
      { "Conditions Governing Access" => ["#{body} See #{html_link} for details."] }
    end

    it "renders the full HTML link without truncating or escaping" do
      render partial: "catalog/restriction_warning", locals: locals

      expect(rendered).not_to have_button("Read full Conditions Governing Access")
      expect(rendered).to have_css(
        "a[href*='access-to-restricted-collections']",
        text: "Access to Restricted Collections policy"
      )
    end
  end
end
