# frozen_string_literal: true
require "rails_helper"

RSpec.describe HoursController, type: :controller do
  describe "#hours" do
    let(:hours_hash) { JSON.parse(response.body) }

    context "with a valid location id" do
      let(:id) { "18717" }

      before { stub_lib_cal(id: id) }

      it "returns a hash with a valid hours value" do
        get :hours, params: { id: id }
        expect(hours_hash["hours"]).to eq "9:00am - 5:00pm"
      end
    end

    context "with an non-valid location id" do
      let(:id) { "99999" }

      before { stub_lib_cal(id: id) }

      it "returns a hash with a unavailable hours value" do
        get :hours, params: { id: id }
        expect(hours_hash["hours"]).to eq "Not available"
      end
    end

    context "with a non-numeric location id" do
      it "returns a hash with a unavailable hours value" do
        get :hours, params: { id: "abcd" }
        expect(hours_hash["hours"]).to eq "Not available"
      end
    end

    context "with no location id" do
      it "returns a hash with a unavailable hours value" do
        get :hours
        expect(hours_hash["hours"]).to eq "Not available"
      end
    end

    context "with a LibCal connection failure" do
      let(:connection) { instance_double("Faraday::Connection") }
      let(:id) { "18717" }

      before do
        stub_lib_cal(id: id)
        allow(Faraday).to receive(:new).and_return(connection)
        allow(connection).to receive(:get).and_raise(Faraday::Error::ConnectionFailed.new("Failed"))
      end

      it "returns a hash with a unavailable hours value" do
        get :hours, params: { id: id }
        expect(hours_hash["hours"]).to eq "Not available"
      end
    end
  end
end
