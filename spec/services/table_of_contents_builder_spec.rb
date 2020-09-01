# frozen_string_literal: true
require "rails_helper"

RSpec.describe TableOfContentsBuilder do
  context "when requesting a full table of contents" do
    it "generates a pruned JSON document of the collection components with no top level component" do
      document = SolrDocument.find("MC221_c0004")
      output = described_class.build(document)
      toc_hash = JSON.parse(output)

      # Ancestor series component
      series_level_components = toc_hash
      series_level_component = series_level_components[0]
      expect(series_level_component["children"].count).to eq 52
      expect(series_level_component["id"]).to eq "MC221_c0001"
      expect(series_level_component["children"]).not_to be_empty
      expect(series_level_component["name"]).to eq "Series 1: U.S. diplomacy career, 1900-1978"

      # Non-ancestor series components have no children, but can be loaded on demand
      expect(series_level_components[1]["children"]).to be_nil
      expect(series_level_components[1]["load_on_demand"]).to be true
      expect(series_level_components[2]["children"]).to be_nil
      expect(series_level_components[2]["load_on_demand"]).to be true

      # Ancestor file level component
      file_level_components = series_level_component["children"]
      file_level_component = file_level_components[1]
      expect(file_level_component["children"].count).to eq 23
      expect(file_level_component["id"]).to eq "MC221_c0003"
      expect(file_level_component["name"]).to eq "Speeches, 1949-1960"

      # Non-ancestor file level components have no children, but can be loaded on demand
      expect(file_level_components[30]["children"]).to be_nil
      expect(file_level_components[30]["load_on_demand"]).to be true
      expect(file_level_components[31]["children"]).to be_nil
      expect(file_level_components[31]["load_on_demand"]).to be true

      selected_component = file_level_component["children"][0]
      expect(selected_component["id"]).to eq "MC221_c0004"
      expect(selected_component["name"]).to eq "National War College, 1949 November 1"
      expect(selected_component["children"]).to be_nil
    end
  end

  context "when requesting toc data for a single node" do
    it "generates a pruned JSON document of the node's child components" do
      document = SolrDocument.find("MC221_c0001")
      output = described_class.build(document, single_node: true)
      toc_hash = JSON.parse(output)

      # Return all child documents
      expect(toc_hash.count).to eq 52

      child_component = toc_hash[1]
      expect(child_component["id"]).to eq "MC221_c0003"
      expect(child_component["name"]).to eq "Speeches, 1949-1960"
      expect(child_component["load_on_demand"]).to be true
      # No deeply nested child components
      expect(child_component["children"]).to be_nil
    end
  end

  context "when requesting a full table of contents where there is a single child component" do
    it "generates a JSON document of the collection components without an error" do
      document = SolrDocument.find("MC148_c00002")
      output = described_class.build(document)
      toc_hash = JSON.parse(output)

      series_level_components = toc_hash
      series_level_component = series_level_components[0]
      expect(series_level_component["id"]).to eq "MC148_c00001"
    end
  end
end
