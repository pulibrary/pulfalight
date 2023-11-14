# frozen_string_literal: true
require "rails_helper"

describe "multiple algorithms", type: :request do
  describe 'search algorithm selection' do
    before do
      allow(Pulfalight).to receive(:multiple_algorithms_enabled?).and_return(true)
    end

    context "when the search_algorithm parameter is not present" do
      it "ranks using the default request handler" do
        get "/catalog.json?q=drawings"
        json = JSON.parse(response.body)

        expect(json["data"][0]["attributes"]["title"]).to eq "Ogonek : roman / ."
      end
    end

    context "when the search_algorithm parameter is set to 'online_content'" do
      it "ranks using the online_content request handler" do
        get "/catalog.json?q=drawings&search_algorithm=online_content"
        json = JSON.parse(response.body)

        expect(json["data"][0]["attributes"]["title"]).to eq "Reconstructing the Vitruvian Scorpio: An Engineering Analysis of Roman Field Artillery"
      end
    end
  end
end
