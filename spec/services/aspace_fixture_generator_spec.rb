# frozen_string_literal: true
require "rails_helper"

RSpec.describe AspaceFixtureGenerator do
  describe "#regenerate!" do
    before do
      FileUtils.rm_rf(Rails.root.join("tmp", "fixture_tests"))
    end
    it "creates an EAD with a small subset of components" do
      client = instance_double(Aspace::Client)
      allow(client).to receive(:ead_url_for_eadid).and_return({ "repositories/1/resource_descriptions/1" => "mss" })
      fixture_generator = described_class.new(
        client: client,
        ead_ids: ["1"],
        component_map: { "1" => ["aspace_C1588_c2"] },
        fixture_dir: Rails.root.join("tmp", "fixture_tests")
      )
      allow(client).to receive(:get)
        .with("repositories/1/resource_descriptions/1.xml", { query: { include_daos: true, include_unpublished: false }, timeout: 1200 })
        .and_return(double(body: File.read(Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C1588.EAD.xml"))))

      fixture_generator.regenerate!

      file_dir = Rails.root.join("tmp", "fixture_tests", "mss")
      expect(File.exist?(file_dir.join("1.EAD.xml"))).to eq true
      content = Nokogiri::XML(File.read(file_dir.join("1.processed.EAD.xml"))).remove_namespaces!
      # Ensure filtered component and all its parents show up in the processed
      # EAD.
      expect(content.search("//c").length).to eq 2
      expect(content.search("//c").map { |x| x["id"] }).to eq ["aspace_C1588_c1", "aspace_C1588_c2"]

      allow(Aspace::Client).to receive(:new).and_raise(ArchivesSpace::ConnectionError)
      # Running it again works without hitting client.
      fixture_generator = described_class.new(
        client: nil,
        ead_ids: ["1"],
        component_map: { "1" => ["aspace_C1588_c2"] },
        fixture_dir: Rails.root.join("tmp", "fixture_tests")
      )

      expect { fixture_generator.regenerate! }.not_to raise_error
    end
  end
end
