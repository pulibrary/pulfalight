# frozen_string_literal: true
require "rails_helper"

describe "search result sorting" do
  describe "sorting by box and folder number", type: :request do
    it "orders results by box then folder number" do
      get "/catalog.json", params: {
        f: { collection_sim: ["Harold B. Hoskins Papers, 1822-1982"] },
        sort: "box_folder_sort_si asc"
      }

      ids = response.parsed_body["data"].pluck("id")

      # box 1, folder 1-3 is first
      expect(ids.first).to eq "MC221_c0002"

      # folder 8 sorted before folder 10
      expect(ids.index("MC221_c0007")).to be < ids.index("MC221_c0009")

      # Has no box and folder, so does not appear in the top results
      expect(ids).not_to include("MC221_c0001")
    end

    it "displays the box and folder sort option only when a collection is selected" do
      get "/catalog", params: { q: "diary" }
      expect(response.body).not_to include("folder number (ascending)")

      get "/catalog", params: { q: "diary", f: { collection_sim: ["Harold B. Hoskins Papers, 1822-1982"] } }
      expect(response.body).to include("folder number (ascending)")
    end
  end
end
