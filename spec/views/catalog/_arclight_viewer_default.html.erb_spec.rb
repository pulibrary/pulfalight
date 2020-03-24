# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_arclight_viewer_default.html.erb", type: :view do
  context "when the digital object is a manifest" do
    let(:manifest_url) { "https://figgy.princeton.edu/concern/scanned_resources/3359153c-82da-4078-ae51-e301f4c5e38b/manifest" }
    let(:document) do
      SolrDocument.new(
        digital_objects_ssm: [{ href: manifest_url, role: UniversalViewer::IIIF_MANIFEST_ROLE }.to_json]
      )
    end

    it "renders universal viewer" do
      assign(:document, document)
      render
      iframe = "<iframe src=\"https://figgy.princeton.edu/viewer#?manifest=#{manifest_url}\" allowfullscreen=\"true\"></iframe>"
      expect(rendered).to include iframe
    end
  end

  context "when the digital object is a link" do
    let(:ark_url) { "http://arks.princeton.edu/ark:/88435/vh53wv96d" }
    let(:json) { "{\"label\":\"#{ark_url}\",\"href\":\"#{ark_url}\",\"role\":null}" }
    let(:document) do
      SolrDocument.new(
        digital_objects_ssm: [json]
      )
    end

    it "renders a link" do
      assign(:document, document)
      render
      link = "<a href=\"#{ark_url}\">#{ark_url}</a>"
      expect(rendered).to include link
    end
  end
end
