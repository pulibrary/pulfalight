# frozen_string_literal: true
require "rails_helper"

RSpec.describe ResearchHelpController, type: :controller do
  describe "#research_help" do
    it "routes to the help page" do
      get :research_help

      expect(response).to be_success
    end
  end
end
