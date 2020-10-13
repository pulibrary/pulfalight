# frozen_string_literal: true
require "rails_helper"

RSpec.describe Aspace::Client do
  before do
    stub_aspace_login
  end
  describe ".new" do
    it "returns a configured ASpace Client" do
      client = described_class.new

      expect(client.config.base_uri).to eq "https://aspace.test.org/staff/api"
      expect(client.config.username).to eq "test"
      expect(client.config.password).to eq "password"
      expect(client.token).to eq "1"
    end
  end
end
