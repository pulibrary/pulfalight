
# frozen_string_literal: true
require 'rails_helper'

describe User do
  subject(:user) { described_class.new }

  describe '#to_s' do
    subject(:user) { described_class.new(email: 'user@institution.edu') }

    it 'uses the e-mail address when providing a string representation' do
      expect(user.to_s).to eq 'user@institution.edu'
    end
  end
end
