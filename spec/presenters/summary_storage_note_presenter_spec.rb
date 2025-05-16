# frozen_string_literal: true
require "rails_helper"

RSpec.describe SummaryStorageNotePresenter do
  subject(:ssnote) { described_class.new(document) }
  let(:document) { SolrDocument.new(values) }
  let(:values) { {} }

  describe "#render" do
    context "with a document that has been indexed to use json" do
      let(:values) do
        {
          "summary_storage_note_ssm": [
            '{"Firestone Library (scahsvm)":["Boxes 1-11; 13-19"],"Firestone Library (scamss)":["Boxes 12; 83; 330; B-001491"]}'
          ]
        }
      end
      it "renders the json as a description list" do
        expect(ssnote.render).to eq(
          ["<span>This is stored in multiple locations.</span>",
           "<dl class=\"storage-notes\">",
           "<dt>Firestone Library (scahsvm)</dt>",
           "<dd>Boxes 1-11; 13-19</dd>",
           "<dt>Firestone Library (scamss)</dt>",
           "<dd>Boxes 12; 83; 330; B-001491</dd>",
           "</dl>"].join
        )
      end
    end

    context "when the storage note has one location, with more than one item type" do
      let(:values) do
        {
          "summary_storage_note_ssm": [
            '{"Firestone Library (scahsvm)":["Boxes 1-11; 13-19", "Volumes 2-4"]}'
          ]
        }
      end
      it "does not say 'multiple locations' and it has two dd tags" do
        expect(ssnote.render).to eq(
          ["<dl class=\"storage-notes\">",
           "<dt>Firestone Library (scahsvm)</dt>",
           "<dd>Boxes 1-11; 13-19</dd>",
           "<dd>Volumes 2-4</dd>",
           "</dl>"].join
        )
      end

      context "when the storage note has a lot of consecutive abid-style box  numbers" do
        let(:values) do
          {
            "summary_storage_note_ssm": [
              '{"Firestone Library (mss)":["Boxes B-001494; B-001495; B-001496; B-001497; B-001498; B-001499; B-001500; B-001501; B-001502; B-001503; B-001504; B-001505; B-001506; B-001507; B-001508; B-001509; B-001510; B-001511; B-001512; B-001515; B-001514; B-001513; B-001516; B-001517; B-001518; B-001519; B-001520; B-001521; B-001522; B-001523; B-001524; B-001525; B-001526; B-001527; B-001528; B-001529; B-001530; B-001531; B-001532; B-001533; B-001534; B-001536; B-001535; B-001537; B-001539; B-001538; B-001540; P-000146; B-001541; B-001542; B-001543; B-001544", "Volumes M-003456; M-003457; M-003458"]}'
            ]
          }
        end
        it "collapses the abid-style box numbers into a range" do
          expect(ssnote.render).to eq(
            ["<dl class=\"storage-notes\">",
             "<dt>Firestone Library (mss)</dt>",
             "<dd>Boxes B-001494 to B-001544, P-000146</dd>",
             "<dd>Volumes M-003456 to M-003458</dd>",
             "</dl>"].join
          )
        end
      end
    end
  end
end
