# frozen_string_literal: true
require 'rails_helper'

describe Pulfa::YearRange do
  subject(:year_range) { described_class.new }

  describe '#parse_ranges' do
    let(:dates) { '1999/2004' }
    it 'parses ranges for dates' do
      expect(year_range.parse_range(dates)).to eq [1999, 2000, 2001, 2002, 2003, 2004]
    end

    context 'when the dates are in reversed order' do
      let(:dates) { '2004/1999' }
      it 'parses ranges for dates in inverted order' do
        expect(year_range.parse_range(dates)).to eq [1999, 2000, 2001, 2002, 2003, 2004]
      end
    end
  end
end
