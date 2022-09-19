# frozen_string_literal: true
require "rails_helper"

RSpec.describe AspaceIndexJob do
  with_queue_adapter :test
  let(:connection) { Blacklight.default_index.connection }

  after do
    connection.delete_by_query("ead_ssi:C1588test*")
    connection.delete_by_query("ead_ssi:C1588testinternal*")
    connection.commit
  end

  describe "indexing" do
    context "when given sync_to_figgy flag" do
      it "enqueues the sync to figgy job" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588.xml")

        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "mss", sync_to_figgy: true)

        expect(SyncToFiggyJob).to have_been_enqueued.with(["C1588test"])
      end
    end

    context "when given a valid existing resource" do
      it "gets it and indexes it" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588.xml")

        connection.delete_by_query("id:C1588test")
        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "mss")
        connection.commit

        items = connection.get("select", params: { q: "id:C1588test" })
        expect(items["response"]["numFound"]).to eq 1
        expect(items["response"]["docs"].first["repository_ssm"]).to eq ["Manuscripts Division"]

        cache = XmlCache.first
        expect(cache.ead_id).to eq "C1588test"
        expect(cache.resource_descriptions_uri).to eq "repositories/13/resources/5396"
        expect(SyncToFiggyJob).not_to have_been_enqueued
      end
    end

    context "when given something with an aspace_uri" do
      it "indexes it as a system identifier" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "publicpolicy/AC300.xml")

        connection.delete_by_query("id:AC300test")
        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "publicpolicy")
        connection.commit

        items = connection.get("select", params: { q: "id:AC300test_c1", fl: "system_identifier_ssm" })
        expect(items["response"]["numFound"]).to eq 1
        expect(items["response"]["docs"].first["system_identifier_ssm"]).to eq ["/repositories/4/archival_objects/683439"]
      end
    end

    context "when given an EAD which is suddenly internal" do
      it "deletes the existing record and its children from solr" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588-internal.xml")

        connection.add({ id: "C1588testinternal", components: { id: "test1", collection_unitid_ssm: "C1588testinternal" } })
        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "mss")
        connection.commit

        items = connection.get("select", params: { q: "id:C1588testinternal" })
        expect(items["response"]["numFound"]).to eq 0
        items = connection.get("select", params: { q: "id:C1588testinternal_c1" })
        expect(items["response"]["numFound"]).to eq 0
      end

      it "can delete an EAD with a period in it" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588-internal-period.xml")

        connection.add({ id: "C1588testinternal-01", components: { id: "test1", collection_unitid_ssm: "C1588testinternal-01" } })
        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "mss")
        connection.commit

        items = connection.get("select", params: { q: "id:C1588testinternal-01" })
        expect(items["response"]["numFound"]).to eq 0
        items = connection.get("select", params: { q: "collection_unitid_ssm:C1588testinternal-01" })
        expect(items["response"]["numFound"]).to eq 0
      end
    end

    context "when given an internal EAD" do
      it "doesn't index it" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588-internal.xml")

        connection.delete_by_query("id:C1588testinternal")
        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "mss")
        connection.commit

        items = connection.get("select", params: { q: "id:C1588testinternal" })
        expect(items["response"]["numFound"]).to eq 0
      end
    end

    context "when given an EAD for a repository that's not configured" do
      it "doesn't index it, alerts via Honeybadger" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588.xml")
        allow(Honeybadger).to receive(:notify)

        connection.delete_by_query("id:C1588test")
        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "test")
        connection.commit

        items = connection.get("select", params: { q: "id:C1588test" })
        expect(items["response"]["numFound"]).to eq 0
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end
end
