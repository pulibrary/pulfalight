# frozen_string_literal: true
require "rails_helper"

describe IndexService do
  let(:instance) { described_class.new }
  let(:search_service) do
    CatalogController.search_service_class.new(config: Blacklight.default_configuration)
  end

  describe "#index_document" do
    it "indexes a single document" do
      fixture_root = Rails.root.join("spec", "fixtures", "ead")
      fixture_rel = File.join("rarebooks", "WC127.EAD.xml")
      instance.index_document(relative_path: fixture_rel, root_path: fixture_root)
      expect(search_service.search_results.first["response"]["numFound"]).to be > 0
    end
  end
end
