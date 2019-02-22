# frozen_string_literal: true
require 'rails_helper'

describe Pulfa::CustomComponent do
  let(:custom_component) do
    described_class.from_xml(file_fixture('ead/alphaomegaalpha.xml'))
  end

  let(:solr_doc) do
    {
      'title_ssm' => ['test title']
    }
  end

  before do
    custom_component.instance_eval do
      def unitdate_inclusive
        ['1902-1976']
      end

      def unitdate_bulk
        ['1912-1986']
      end

      def unitdate_other
        ['1992']
      end
    end

    custom_component.add_normalized_title(solr_doc)
  end

  describe '#add_normalized_title' do
    it 'tries to append the date range to the title' do
      expect(solr_doc['normalized_title_ssm']).to eq ['test title, 1902-1976, bulk 1912-1986']
      expect(solr_doc['normalized_date_ssm']).to eq ['1902-1976, bulk 1912-1986']
    end

    context 'when there are no dates in the document' do
      let(:custom_component) do
        described_class.from_xml(file_fixture('ead/alphaomegaalpha.xml'))
      end

      let(:solr_doc) do
        {
          'title_ssm' => ['test title']
        }
      end

      before do
        custom_component.instance_eval do
          def unitdate_inclusive
            []
          end

          def unitdate_bulk
            []
          end

          def unitdate_other
            []
          end
        end

        custom_component.add_normalized_title(solr_doc)
      end

      it 'defaults to just the title' do
        expect(solr_doc['normalized_title_ssm']).to eq ['test title']
        expect(solr_doc['normalized_date_ssm']).to eq [nil]
      end
    end
  end
end
