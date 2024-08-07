# frozen_string_literal: true
require "rails_helper"

RSpec.describe SyncToFiggyJob do
  describe "#perform" do
    context "when Figgy returns a 2xx response" do
      it "completes" do
        stub_refresh_remote_metadata(status_code: 202)
        described_class.perform_now(["C0001"])

        expect(WebMock).to have_requested(:post, "https://figgy.princeton.edu/resources/refresh_remote_metadata?auth_token=123456")
          .with(body: { "archival_collection_codes" => ["C0001"] })
      end
    end

    context "when Figgy returns a 500 response" do
      it "raises an exception" do
        stub_refresh_remote_metadata(status_code: 500)
        expect { described_class.perform_now(["C0001"]) }.to raise_exception(SyncToFiggyJob::FiggyError)
      end
    end

    context "when there's no auth token" do
      it "aborts" do
        config = Pulfalight.config.clone
        config.delete("figgy_auth_token")
        allow(Pulfalight).to receive(:config).and_return(config)
        # do not stub wemock, expect the connection to not be attempted
        expect { described_class.perform_now(["C0001"]) }.not_to raise_error(WebMock::NetConnectNotAllowedError)
      end
    end
  end
end
