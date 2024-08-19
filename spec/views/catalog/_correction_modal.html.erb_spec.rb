# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_correction_modal.html.erb" do
  let(:document) do
    {
      "ead_ssi" => "MC001.02.06",
      "id" => ["MC001-02-06"],
      "repository_code_ssm" => ["fake repository code"]

    }
  end
  let(:solr_document) { SolrDocument.new(document) }

  it "renders the suggest a correction modal, with instructions" do
    assign :document, solr_document
    render partial: "catalog/correction_modal"
    content = view.content_for(:correction_modal)
    expect(content).to have_content("Please use this area to report errors or omissions")
  end
end
