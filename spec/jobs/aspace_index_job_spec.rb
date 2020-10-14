# frozen_string_literal: true
require "rails_helper"

RSpec.describe AspaceIndexJob do
  let(:connection) { Blacklight.default_index.connection }
  describe "indexing" do
    context "when given a valid existing resource" do
      it "gets it and indexes it" do
        stub_aspace_login
        stub_aspace_ead(resource_descriptions_uri: "repositories/13/resources/5396", ead: "mss/C1588.xml")

        described_class.perform_now(resource_descriptions_uri: "repositories/13/resources/5396", repository_id: "mss")
        connection.commit

        items = connection.get("select", params: { q: "id:C1588test" })
        expect(items["response"]["numFound"]).to eq 1
        expect(items["response"]["docs"].first["repository_ssm"]).to eq ["Manuscripts Division"]
      end
    end
  end
end
