# frozen_string_literal: true

require "rails_helper"
include BuildSolrDocument

describe PulfalightHelper, type: :helper do
  let(:solr_response) { instance_double(Blacklight::Solr::Response) }
  let(:search_service) { instance_double(Blacklight::SearchService) }
  let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002.json") }

  describe "#current_year" do
    let(:output) { helper.current_year }
    it "returns the current year" do
      expect(output).to eq DateTime.current.year
    end
  end

  describe "#repository_config_present?" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.repository_config_present?(nil, document) }

    it "determines whether or not a configuration for a repository exists for a document" do
      expect(output).to be(false)
    end

    context "when the repository exists" do
      let(:repository) { instance_double(Arclight::Repository) }

      before do
        allow(Arclight::Repository).to receive(:find_by).and_return(repository)
      end

      it "finds the repository" do
        expect(output).to be(true)
      end
    end
  end

  describe "#request_config_present" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.request_config_present?(nil, document) }
    let(:repository) { instance_double(Arclight::Repository) }

    before do
      allow(Arclight::Repository).to receive(:find_by).and_return(repository)
    end

    it "determines if a request management system is configured" do
      expect(output).to be(true)
    end
  end

  describe "#aeon_external_request" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.aeon_external_request(document) }
    let(:presenter) { Arclight::ShowPresenter }

    before do
      allow(helper).to receive(:show_presenter).and_return(presenter)
    end

    it "builds an object used for external requests to Aeon" do
      expect(output).to be_a Pulfalight::Requests::AeonExternalRequest
    end
  end

  describe "#normalize_id" do
    let(:output) { helper.normalize_id("C0002") }
    it "generates a normalized ID from the document" do
      expect(output).to eq("C0002")
    end

    context "without a valid ID" do
      let(:output) { helper.normalize_id(nil) }
      it "generates a random string" do
        expect(output).not_to be_empty
      end
    end
  end

  describe "#document_parents" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002_c001.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.document_parents(document) }
    it "builds the Parent objects Solr Document" do
      expect(output).not_to be_empty
      expect(output.first).to be_a(Arclight::Parent)
    end
  end

  describe "#parents_to_links" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002_c001.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.parents_to_links(document) }
    it "builds the URLs for the parent Solr Documents" do
      expect(output).not_to be_empty
      expect(output).to include("<span></span><span aria-hidden=\"true\"> » </span><a href=\"/catalog/")
      expect(output).to include("\">Penelope Pennington Collection, 1798-1827</a>")
    end
  end

  describe "#overridden_document_parents" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002_c001.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.overridden_document_parents(document) }
    it "builds the Parent objects Solr Document" do
      expect(output).not_to be_empty
      expect(output.first).to be_a(Arclight::Parent)
    end
  end

  describe "#overridden_parents_to_links" do
    let(:fixture_file_path) { Rails.root.join("spec", "fixtures", "C0002_c001.json") }
    let(:document) { build_solr_document(fixture_file_path, solr_response) }
    let(:output) { helper.overridden_parents_to_links(document) }
    it "builds the URLs for the parent Solr Documents" do
      expect(output).not_to be_empty
      expect(output).to include("<span></span><span aria-hidden=\"true\"> » </span><a href=\"/catalog/")
      expect(output).to include("\">Penelope Pennington Collection, 1798-1827</a>")
    end
  end
end
