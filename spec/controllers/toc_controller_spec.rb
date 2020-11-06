# frozen_string_literal: true
require "rails_helper"

RSpec.describe TocController, type: :controller do
  describe "#toc" do
    let(:toc) { JSON.parse(response.body) }
    context "requesting a partial tree" do
      it "returns only child nodes" do
        get :toc, params: { node: "aspace_MC221_c0001" }
        expect(toc.count).to eq 52
        expect(toc[0]["id"]).to eq "aspace_MC221_c0002"
        expect(toc[0]["children"]).to be_nil
        expect(toc[1]["id"]).to eq "aspace_MC221_c0003"
        expect(toc[1]["children"]).to be_truthy
      end
    end
    context "requesting a full tree" do
      it "returns full tree without the top-level collection" do
        get :toc, params: { node: "aspace_MC221_c0001", full: true }
        expect(toc.count).to eq 3
        expect(toc[0]["id"]).to eq "aspace_MC221_c0001"
      end
    end
    context "with a node that has no corresponding record" do
      it "returns an empty json object" do
        get :toc, params: { node: "not-found" }
        expect(response.body).to eq "{}"
      end
    end
  end
end
