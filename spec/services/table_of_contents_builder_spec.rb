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
      expect(series_level_components[1]["state"]["opened"]).to eq false
      expect(series_level_component["children"].count).to eq 52
      expect(series_level_component["id"]).to eq "MC221_c0001"
      expect(series_level_component["children"]).not_to be_empty
      expect(series_level_component["text"]).to eq "<div class='content'><span class='text'>Series 1: U.S. diplomacy career, 1900-1978</span></div>"

      # Non-ancestor series components have no children, but can be loaded on demand
      expect(series_level_components[1]["children"]).to be_truthy
      expect(series_level_components[2]["children"]).to be_truthy

      # Ancestor file level component
      file_level_components = series_level_component["children"]
      file_level_component = file_level_components[1]
      expect(file_level_component["children"].count).to eq 23
      expect(file_level_component["id"]).to eq "MC221_c0003"
      expect(file_level_component["text"]).to eq "<div class='content'><span class='text'>Speeches, 1949 November-1960 February</span></div>"

      # Non-ancestor file level components have no children, but can be loaded on demand
      expect(file_level_components[30]["children"]).to be_truthy
      expect(file_level_components[31]["children"]).to be_truthy

      selected_component = file_level_component["children"][0]
      expect(selected_component["id"]).to eq "MC221_c0004"
      expect(selected_component["text"]).to eq "<div class='content'><span class='text'>National War College, 1949 November 1</span></div>"
      expect(selected_component["children"]).to be_nil
      # Ensure that the ToC node you request is opened.
      expect(selected_component["state"]["opened"]).to eq true
    end
  end

  context "when requesting toc data for a full tree, with a middle level component selected" do
    it "generates a full JSON document, but only opens the correct level" do
      document = SolrDocument.find("MC221_c0001")
      output = described_class.build(document)
      toc_hash = JSON.parse(output)

      # Ancestor series component
      series_level_components = toc_hash
      series_level_component = series_level_components[0]
      expect(series_level_component["state"]["opened"]).to eq true
      expect(series_level_component["children"][0]["state"]["opened"]).to eq false
    end
  end

  context "when requesting toc data for a single node" do
    it "generates a pruned JSON document of the node's child components" do
      document = SolrDocument.find("MC221_c0001")
      output = described_class.build(document, single_node: true)
      toc_hash = JSON.parse(output)

      # Return all child documents
      expect(toc_hash.count).to eq 52
      expect(toc_hash[0]["state"]["opened"]).to eq false

      child_component = toc_hash[1]
      expect(child_component["id"]).to eq "MC221_c0003"
      expect(child_component["text"]).to eq "<div class='content'><span class='text'>Speeches, 1949 November-1960 February</span></div>"
      # Ensure it doesn't load it as opened when requesting a single node - this
      # happens when clicking the "arrow"
      expect(child_component["state"]["opened"]).to eq false
      # No deeply nested child components
      expect(child_component["children"]).to be_truthy
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

  context "when rendering a series whose children has online content" do
    it "marks them with a li_attr class" do
      document = SolrDocument.find("MC148_c00002")
      output = described_class.build(document)
      toc_hash = JSON.parse(output)

      series_level_components = toc_hash
      series_level_component = series_level_components[1]
      expect(series_level_component["li_attr"]).to eq({ "data-online-content" => true })
      expect(series_level_component["text"]).to include "online-indirect-content"
      expect(series_level_component["text"]).to include "Some online content"
    end
  end
end
