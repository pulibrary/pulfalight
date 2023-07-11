# frozen_string_literal: true
require "rails_helper"

RSpec.describe OnlineContentBanner do
  subject(:badge) { described_class.new(document) }
  let(:document) { SolrDocument.new(values) }
  let(:values) { {} }

  describe "#render" do
    context "with a document that has no online content" do
      it "returns nil" do
        expect(badge.render).to be_nil
      end
    end

    context "with a document that has indirect online content" do
      let(:values) { { has_online_content_ssim: ["true"] } }

      it "returns a badge with a some online content label" do
        expect(badge.render).to include("Some materials in this collection are available online.")
      end
    end

    context "with a document that has direct online content" do
      let(:values) do
        {
          has_online_content_ssim: ["true"],
          has_direct_online_content_ssim: ["true"]
        }
      end

      it "returns a badge with an online content label" do
        expect(badge.render).to include("All materials in this collection are available online.")
      end
    end
  end
end
