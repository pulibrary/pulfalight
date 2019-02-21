# frozen_string_literal: true
require 'rails_helper'

describe Pulfa::Indexer do
  subject(:indexer) { described_class.new }

  describe '#normalize_title' do
    let(:data) do
      {
        title: 'Collection title',
        unitdate_inclusive: '1902-1976',
        unitdate_bulk: '1975-1976',
        unitdate_other: 'n.d.'
      }
    end
    let(:normalized_title) { indexer.normalize_title(data) }

    it 'generates a normalized title with a normalized title and dates from the <unitdate> elements' do
      expect(normalized_title).to eq 'Collection title, 1902-1976, bulk 1975-1976'
    end
  end
end
