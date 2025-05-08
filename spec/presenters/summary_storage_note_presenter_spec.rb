# frozen_string_literal: true
require "rails_helper"

RSpec.describe SummaryStorageNotePresenter do
  subject(:ssnote) { described_class.new(document) }
  let(:document) { SolrDocument.new(values) }
  let(:values) { {} }

  describe "#render" do
    context "with a document that has not been reindexed yet" do
      let(:values) do
        {
          "summary_storage_note_ssm": [
            "This is stored in multiple locations.",
            "Firestone Library (scahsvm): Boxes 1-11; 13-19",
            "Firestone Library (scamss): Boxes 12; 20-21"
          ]
        }
      end
      it "renders the array of strings as a list" do
        expect(ssnote.render).to eq(
          ["<ul>",
           "<li>This is stored in multiple locations.</li>",
           "<li>Firestone Library (scahsvm): Boxes 1-11; 13-19</li>",
           "<li>Firestone Library (scamss): Boxes 12, 20 to 21</li>",
           "</ul>"].join
        )
      end
    end

    context "with a document that has been indexed to use json" do
      let(:values) do
        {
          "summary_storage_note_ssm": [
            '{"Firestone Library (scahsvm)":["Boxes 1-11; 13-19"],"Firestone Library (scamss)":["Boxes 12; 83; 330; B-001491"]}'
          ]
        }
      end
      it "renders the json as nested lists" do
        expect(ssnote.render).to eq(
          ["<span>This is stored in multiple locations.</span>",
           "<ul>",
           "<li>Firestone Library (scahsvm)</li>",
           "<ul><li>Boxes 1-11; 13-19</li></ul>",
           "<li>Firestone Library (scamss)</li>",
           "<ul><li>Boxes 12; 83; 330; B-001491</li></ul>",
           "</ul>"].join
        )
      end
    end
  end
end
