# frozen_string_literal: true

require "rails_helper"

RSpec.describe Arclight::SolrDocument do
  let(:values) { {} }
  let(:document) { SolrDocument.new(values) }

  describe "custom accessors" do
    it { expect(document).to respond_to(:parent_ids) }
    it { expect(document).to respond_to(:parent_labels) }
    it { expect(document).to respond_to(:eadid) }
  end

  context "when collections or components link to digital objects" do
    let(:digital_object) do
      {
        "label" => "https://figgy.princeton.edu/concern/scanned_resources/3918d320-6563-4e4b-9fdf-2729ec6480a6/manifest",
        "href" => "https://figgy.princeton.edu/concern/scanned_resources/3918d320-6563-4e4b-9fdf-2729ec6480a6/manifest",
        "role" => "https://iiif.io/api/presentation/2.1/"
      }
    end
    let(:values) do
      {
        "digital_objects_ssm": [digital_object.to_json],
        "direct_digital_objects_ssm": [digital_object.to_json]
      }
    end

    describe "#digital_objects" do
      it "builds DigitalObjects from the links" do
        expect(document.digital_objects).not_to be_empty

        digital_object = document.digital_objects.first
        expect(digital_object).to be_a(Pulfalight::DigitalObject)

        expect(digital_object.label).to eq("https://figgy.princeton.edu/concern/scanned_resources/3918d320-6563-4e4b-9fdf-2729ec6480a6/manifest")
        expect(digital_object.href).to eq("https://figgy.princeton.edu/concern/scanned_resources/3918d320-6563-4e4b-9fdf-2729ec6480a6/manifest")
        expect(digital_object.role).to eq("https://iiif.io/api/presentation/2.1/")
      end
    end

    describe "#direct_digital_objects" do
      it "builds DigitalObjects from the links" do
        expect(document.direct_digital_objects).not_to be_empty

        digital_object = document.direct_digital_objects.first
        expect(digital_object).to be_a(Pulfalight::DigitalObject)

        expect(digital_object.label).to eq("https://figgy.princeton.edu/concern/scanned_resources/3918d320-6563-4e4b-9fdf-2729ec6480a6/manifest")
        expect(digital_object.href).to eq("https://figgy.princeton.edu/concern/scanned_resources/3918d320-6563-4e4b-9fdf-2729ec6480a6/manifest")
        expect(digital_object.role).to eq("https://iiif.io/api/presentation/2.1/")
      end
    end
  end
end
