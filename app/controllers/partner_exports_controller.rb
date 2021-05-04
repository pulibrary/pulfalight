# frozen_string_literal: true
class PartnerExportsController < ApplicationController
  # PACSCL just needs straight links to the XML for every collection, but with
  # no containers.
  def pacscl
    @collections = collections
    render layout: "empty"
  end

  def collections
    Blacklight.default_index.search(q: "level_ssm:collection", fl: "id, normalized_title_ssm", rows: 10_000)["response"]["docs"]
  end
end
