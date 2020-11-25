# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolrDocumentTree do
  subject(:solr_document_tree) { described_class.new(root: solr_document) }

  let(:solr_document) do
    SolrDocument.find("MC152")
  end

  context "when the Solr Document contains one or more member components" do
    describe "#children" do
      it "builds child SolrDocumentTree objects for each component" do
        expect(solr_document_tree.children).not_to be_empty
        expect(solr_document_tree.children.first).to be_a described_class
        expect(solr_document_tree.children.first.root).to be_a SolrDocument
        expect(solr_document_tree.children.first.root.id).to eq("aspace_MC152_c001")
        expect(solr_document_tree.children.last.root).to be_a SolrDocument
        expect(solr_document_tree.children.last.root.id).to eq("aspace_MC152_c010")
      end
    end
  end
end
