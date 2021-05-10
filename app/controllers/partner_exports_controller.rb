# frozen_string_literal: true
class PartnerExportsController < ApplicationController
  # PACSCL just needs straight links to the XML for every collection, but with
  # no containers.
  def pacscl
    @collections = collections
    render layout: "empty"
  end

  # PACSCL needs links that end in .xml, and absolutely can't follow redirects,
  # so we provide a special getter for them here.
  def pacscl_xml
    document = Blacklight.default_index.search(q: "id:#{params[:id]}")&.dig("response", "docs")&.first
    document = SolrDocument.new(document)
    document.suppress_xml_containers!
    respond_to do |format|
      format.xml do
        render xml: document.export_as_xml
      end
    end
  end

  def collections
    Blacklight.default_index.search(q: "level_ssm:collection", fl: "id, normalized_title_ssm", rows: 10_000)["response"]["docs"]
  end
end
