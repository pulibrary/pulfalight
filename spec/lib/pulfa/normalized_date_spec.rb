# frozen_string_literal: true
require 'rails_helper'

describe Pulfa::NormalizedDate do
  subject(:normalized_date) { described_class.new(date_inclusive, date_bulk, date_other) }

  let(:date_inclusive) { '1990-2000' }
  let(:date_bulk) { '1999-2005' }
  let(:date_other) { nil }

  describe '.new' do
    it 'constructs a new normalized date' do
      expect(normalized_date.to_s).to eq '1990-2000, bulk 1999-2005'
    end

    context 'with a formatted inclusive date year range' do
      let(:date_inclusive) { %w[1999/2004] }

      it 'constructs a new normalized date with range parsed' do
        expect(normalized_date.to_s).to eq '1999-2004, bulk 1999-2005'
      end
    end
  end
end
