# frozen_string_literal: true
require "rails_helper"

describe "catalog/_show_collection_title" do
  context "when collection id has dots" do
    let(:document) do
      {
        "ead_ssi" => "MC001.02.06",
        "id" => ["MC001-02-06"],
        "level_ssm" => ["collection"],
        "title_ssm" => ["American Civil Liberties Union Records: Subgroup 2, Audiovisual Materials Series"],
        "collection_ssm" => ["American Civil Liberties Union Records: Subgroup 2, Audiovisual Materials Series, 1947-1995"]
      }
    end
    let(:solr_document) { SolrDocument.new(document) }

    it "renders the correct link" do
      assign :document, solr_document
      render

      expect(rendered).to have_link("American Civil Liberties Union Records: Subgroup 2, Audiovisual Materials Series, 1947-1995", href: "/catalog/MC001-02-06")
    end
  end

  context "when a compent id has dots" do
    let(:document) do
      {
        "ead_ssi" => "MC001.02.06",
        "id" => ["aspace_MC001-02-06_c0001"],
        "level_ssm" => ["Series"],
        "title_ssm" => ["Series 6, Audio-Visual materials"],
        "collection_ssm" => ["American Civil Liberties Union Records: Subgroup 2, Audiovisual Materials Series, 1947-1995"]
      }
    end
    let(:solr_document) { SolrDocument.new(document) }

    it "renders the correct link" do
      assign :document, solr_document
      render

      expect(rendered).to have_link("American Civil Liberties Union Records: Subgroup 2, Audiovisual Materials Series, 1947-1995", href: "/catalog/MC001-02-06")
    end
  end
end
