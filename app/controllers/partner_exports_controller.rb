# frozen_string_literal: true
class PartnerExportsController < ApplicationController
  # PACSCL just needs straight links to the XML for every collection, but with
  # no containers.
  def pacscl
    @collections = collections
    render layout: "empty"
  end

  # PACSCL links NEED to end in .xml, so we provide this redirect to point to
  # the content without containers.
  def pacscl_redirect
    redirect_to "/catalog/#{params[:id]}.xml?containers=false"
  end

  def collections
    Blacklight.default_index.search(q: "level_ssm:collection", fl: "id, normalized_title_ssm", rows: 10_000)["response"]["docs"]
  end
end
