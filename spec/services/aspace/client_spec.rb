# frozen_string_literal: true
require "rails_helper"

RSpec.describe Aspace::Client do
  before do
    stub_aspace_login
    stub_aspace_repositories
    stub_aspace_resource_ids(repository_id: "13", resource_ids: ["1", "2", "3"])
    stub_aspace_resource_ids(repository_id: "13", modified_since: Time.zone.parse("2020-01-09").to_i, resource_ids: ["3"])
  end
  describe ".new" do
    it "returns a configured ASpace Client" do
      client = described_class.new

      expect(client.config.base_uri).to eq "https://aspace.test.org/staff/api"
      expect(client.config.username).to eq "test"
      expect(client.config.password).to eq "password"
      expect(client.token).to eq "1"
    end
  end

  describe "#ead_url_for_eadid" do
    it "returns the EAD URL and repository code for a given eadid" do
      client = described_class.new

      expect(client.ead_url_for_eadid(eadid: "3")).to eq(
        {
          "repositories/13/resource_descriptions/3" => "mss"
        }
      )
    end
  end

  describe "ead_urls" do
    it "returns EAD urls for all 2020 and later repositories, grouped by repository code" do
      client = described_class.new

      expect(client.ead_urls).to eq(
        {
          "mss" => [
            "repositories/13/resource_descriptions/1",
            "repositories/13/resource_descriptions/2",
            "repositories/13/resource_descriptions/3"
          ]
        }
      )
    end
    context "when given modified_since" do
      it "passes it" do
        client = described_class.new

        expect(client.ead_urls(modified_since: Time.zone.parse("2020-01-09").to_i)).to eq(
          {
            "mss" => [
              "repositories/13/resource_descriptions/3"
            ]
          }
        )
      end
    end
  end
end
