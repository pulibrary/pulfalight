# frozen_string_literal: true
require "rails_helper"

RSpec.describe OnlineContentBadge do
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

      it "returns a badge with a some online material label" do
        expect(badge.render).to include("document-access online-content online-indirect-content", "SOME ONLINE MATERIAL")
      end
    end

    context "with a document that has direct online content" do
      let(:values) do
        {
          has_online_content_ssim: ["true"],
          has_direct_online_content_ssim: ["true"]
        }
      end

      it "returns a badge with an online material label" do
        expect(badge.render).to include("document-access online-content online-direct-content", "HAS ONLINE MATERIAL")
      end
    end
  end
end
