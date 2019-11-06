# frozen_string_literal: true
require "rails_helper"

# Integration test for Viewer documented at
# https://github.com/projectblacklight/arclight/wiki/Digital-Object-Viewers
# Strategy: Implement an Arclight::Viewer using documentation at
# https://github.com/projectblacklight/arclight/wiki/Digital-Object-Viewers and
# make sure it renders here.
RSpec.describe "catalog/_arclight_viewer_default.html.erb", type: :view do
  let(:figgy_id) { "3359153c-82da-4078-ae51-e301f4c5e38b" }
  let(:document_id) { "MC221MC221_c0094" }
  let(:search_service) { CatalogController.search_service_class.new(config: Blacklight.default_configuration) }
  #let(:document) { search_service.fetch(document_id).last }

  before do
    fixture_file = Rails.root.join("spec", "fixtures", "ead", "mudd", "publicpolicy", "MC221.EAD.xml")
    IndexJob.perform_now([fixture_file])
    Blacklight.default_index.connection.commit
  end

  let(:document) do
    SolrDocument.new(
      digital_objects_ssm: [{
        href: "https://figgy.princeton.edu/concern/scanned_resources/3359153c-82da-4078-ae51-e301f4c5e38b/manifest"
      }.to_json]
    )

  end

  # TODO: just make a solr doc as in
  # https://github.com/projectblacklight/arclight/blob/a1ec06251b5a937e785d32ef74f2adb817df5ae6/spec/lib/arclight/viewer_spec.rb
  # instead of using search service
  it "renders universal viewer" do
    assign(:document, document)
    render
    iframe = "<iframe src=\"https://figgy.princeton.edu/viewer#?manifest=https://figgy.princeton.edu/concern/scanned_resources/#{figgy_id}/manifest\" allowfullscreen=\"true\"></iframe>"
    expect(rendered).to include iframe
  end

  # TODO: Add a test for a non-figgy DAO.
  # do we need to index role and ensure it's "https://iiif.io/api/presentation/2.1/"
end
