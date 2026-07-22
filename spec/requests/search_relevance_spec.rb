# frozen_string_literal: true
require "rails_helper"

describe "search relevance", type: :request do
  context "when a document matches only through the parent document title" do
    it "is ranked below a document that matches on it's own values" do
      get "/catalog.json?q=beloved&search_field=all_fields"
      ids = JSON.parse(response.body)["data"].map { |doc| doc["id"] }

      # Smith, James McCune, 1985 February
      # Parent title is "Beloved Research Files, 1985-1986"
      parent_title_match = "C1491_c68"

      # Cyrano (unpublished), 1976
      # scopecontent_ssm contains the word "beloved"
      own_field_match = "ref293"
      expect(ids).to include(parent_title_match, own_field_match)
      expect(ids.index(own_field_match)).to be < ids.index(parent_title_match)
    end
  end
end
