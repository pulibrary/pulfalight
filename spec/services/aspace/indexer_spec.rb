# frozen_string_literal: true
require "rails_helper"

RSpec.describe Aspace::Indexer do
  describe ".index_new" do
    before do
      stub_aspace_login
      stub_aspace_repositories
      stub_aspace_resource_ids(repository_id: "13", resource_ids: ["1", "2", "3"])
      stub_aspace_resource_ids(repository_id: "13", modified_since: Time.zone.parse("2020-01-09").to_i, resource_ids: ["3"])
    end
    after do
      Timecop.return
    end
    it "queues everything that needs indexed, and keeps track" do
      allow(AspaceIndexJob).to receive(:perform_later)
      Timecop.freeze(Time.zone.parse("2020-01-09"))

      # Never run before - it should index everything, and keep track of when it
      # last indexed.
      described_class.index_new
      event = Event.first

      Timecop.freeze(Time.zone.parse("2020-01-10"))

      # It's running again, and knows when it last indexed, so it should only
      # ask for those after the last time.
      described_class.index_new

      expect(Event.first.updated_at).not_to eq event.updated_at

      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/1",
        repository_id: "mss",
        soft: false, sync_to_figgy: true
      ).exactly(1).times
      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/2",
        repository_id: "mss", soft: false,
        sync_to_figgy: true
      ).exactly(1).times
      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/3",
        repository_id: "mss", soft: false,
        sync_to_figgy: true
      ).exactly(2).times
    end
  end

  describe ".soft_full_reindex" do
    before do
      stub_aspace_login
      stub_aspace_repositories
      stub_aspace_resource_ids(repository_id: "13", resource_ids: ["1"])
    end
    it "reindexes everything by using the XML Cache" do
      resource_ead_stub = stub_aspace_ead(resource_descriptions_uri: "repositories/13/resource_descriptions/1", ead: "mss/C1588.xml")
      allow(AspaceIndexJob).to receive(:perform_later).and_call_original
      # Full reindex to populate the XML cache.
      described_class.full_reindex

      described_class.soft_full_reindex

      expect(resource_ead_stub).to have_been_made.times(1)
      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/1",
        repository_id: "mss",
        soft: true,
        sync_to_figgy: false
      ).exactly(1).times
    end
  end

  describe ".full_reindex" do
    before do
      stub_aspace_login
      stub_aspace_repositories
      stub_aspace_resource_ids(repository_id: "13", resource_ids: ["1", "2", "3"])
      stub_aspace_resource_ids(repository_id: "13", modified_since: Time.zone.parse("2020-01-09").to_i, resource_ids: ["3"])
    end
    it "queues everything that needs indexed, and keeps track" do
      allow(AspaceIndexJob).to receive(:perform_later)
      Timecop.freeze(Time.zone.parse("2020-01-09"))

      described_class.full_reindex
      event = Event.first

      Timecop.freeze(Time.zone.parse("2020-01-10"))

      described_class.full_reindex

      # Ensure the event time still gets updated
      expect(Event.first.updated_at).not_to eq event.updated_at

      # Full reindexes will queue more jobs no matter what.
      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/1",
        repository_id: "mss",
        soft: false,
        sync_to_figgy: false
      ).exactly(2).times
      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/2",
        repository_id: "mss",
        soft: false,
        sync_to_figgy: false
      ).exactly(2).times
      expect(AspaceIndexJob).to have_received(:perform_later).with(
        resource_descriptions_uri: "repositories/13/resource_descriptions/3",
        repository_id: "mss",
        soft: false,
        sync_to_figgy: false
      ).exactly(2).times
    end
  end
end
