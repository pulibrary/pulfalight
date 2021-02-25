# frozen_string_literal: true
require "rails_helper"

RSpec.describe AboutController, type: :controller do
  describe "#research_help" do
    it "routes to the Research Help page" do
      get :research_help

      expect(response).to be_successful
    end
  end
  describe "#archival_language" do
    it "routes to the Statement on Archival Language page" do
      get :archival_language

      expect(response).to be_successful
    end
  end
  describe "#av_materials" do
    it "routes to the AV Materials page" do
      get :av_materials

      expect(response).to be_successful
    end
  end
  describe "#faq" do
    it "routes to the FAQ page" do
      get :faq

      expect(response).to be_successful
    end
  end
  describe "#requesting_materials" do
    it "routes to the Requesting Materials page" do
      get :requesting_materials

      expect(response).to be_successful
    end
  end
  describe "#research_account" do
    it "routes to the Research Account page" do
      get :research_account

      expect(response).to be_successful
    end
  end
  describe "#search_tips" do
    it "routes to the Search Tips page" do
      get :search_tips

      expect(response).to be_successful
    end
  end
end
