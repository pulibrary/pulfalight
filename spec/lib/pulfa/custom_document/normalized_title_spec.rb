# frozen_string_literal: true
require 'rails_helper'

describe Pulfa::CustomDocument::NormalizedTitle do
  subject(:normalized_title) { described_class.new(title, date) }

  let(:title) { 'test title' }
  let(:date) { '01/01/1970' }

  describe '#to_s' do
    let(:title) { '  test title, test subtitle ' }
    let(:date) { '  01/01/1970 ' }

    it 'normalizes the title and date values by formatting them' do
      expect(normalized_title.to_s).to eq 'test title, test subtitle, 01/01/1970'
    end
  end
end
