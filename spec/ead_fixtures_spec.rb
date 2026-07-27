# frozen_string_literal: true
require "rails_helper"

RSpec.describe "EAD fixtures" do
  # Make sure no duplicate @id's sneak in so we don't get an XML schema validation error
  describe "agent-side bioghists" do
    let(:document) do
      path = Rails.root.join("spec", "fixtures", "aspace", "generated", "mss", "C0140.processed.EAD.xml")
      Nokogiri::XML(File.read(path)).remove_namespaces!
    end
    let(:agent_bioghists) { document.xpath('//bioghist[note[@label="personal-name"]]') }

    it "has fixtures with agent-side bioghist notes" do
      expect(agent_bioghists).not_to be_empty
    end

    it "does not copy over their persistent id's" do
      expect(agent_bioghists.map { |bioghist| bioghist["id"] }.compact).to be_empty
    end

    it "does not repeat any @id values'" do
      ids = document.xpath("//@id").map(&:value)
      expect(ids.tally.select { |_id, count| count > 1 }).to be_empty
    end
  end
end
