# frozen_string_literal: true
require 'rails_helper'

describe Pulfa::CustomDocument do
  subject(:document) do
    described_class.from_xml(ead_document)
  end
  let(:ead_file) { File.open(Rails.root.join('spec', 'fixtures', 'files', 'AC162.EAD.xml')) }
  let(:ead_document) do
    Nokogiri::XML.parse(ead_file) do |config|
      config.options = Nokogiri::XML::ParseOptions::HUGE
    end
  end
  let(:solr_document) do
    {}
  end

  describe '#add_normalized_title' do
    before do
      document.add_normalized_title(solr_document)
    end
    it 'adds the normalized title and dates into the Solr Document' do
      expect(solr_document).to include 'normalized_title_ssm'
      expect(solr_document['normalized_title_ssm']).to eq ['1884-2017']
      expect(solr_document).to include 'normalized_date_ssm'
      expect(solr_document['normalized_date_ssm']).to eq ['1884-2017']
    end
  end

  describe '#add_digital_content' do
    let(:output) { document.add_digital_content(prefix: '/', solr_doc: solr_document) }
    it 'adds the digital object links into the Solr Document' do
      expect(output).not_to be_empty
      first_value = JSON.parse(output.first)
      expect(first_value).to include("href" => "https://wayback.archive-it.org/5151/*/http://www.princeton.edu/engineering/")
      expect(first_value).to include("label" => "https://wayback.archive-it.org/5151/*/http://www.princeton.edu/engineering/")
      expect(solr_document).to include 'digital_objects_ssm'
      expect(solr_document['digital_objects_ssm']).not_to be_empty
      expect(JSON.parse(solr_document['digital_objects_ssm'].first)).to eq first_value
    end
  end

  describe '#digital_objects' do
    let(:output) { document.digital_objects }
    it 'generates the JSON Object for digital objects and adds them into the Solr Document' do
      expect(output).not_to be_empty
      first_value = JSON.parse(output.first)
      expect(first_value).to include("href" => "https://wayback.archive-it.org/5151/*/http://www.princeton.edu/engineering/")
      expect(first_value).to include("label" => "https://wayback.archive-it.org/5151/*/http://www.princeton.edu/engineering/")
    end
  end

  describe '#online_content?' do
    it 'determines whether or not the Document contains links to online content' do
      expect(document.online_content?).to be true
    end
  end

  describe '#unitdate_for_range' do
    it 'generates a single date string for a range of values' do
      expect(document.unitdate_for_range).to be_a Pulfa::YearRange
      expect(document.unitdate_for_range.to_s).to eq '1884-2017'
    end
  end
end
