# frozen_string_literal: true

class SyncToFiggyJob < ApplicationJob
  class FiggyError < StandardError; end

  def perform(collection_ids)
    connection = Faraday.new(
      url: Pulfalight.config["figgy_url"],
      headers: { "Content-Type" => "application/json" }
    )
    auth_token = Pulfalight.config["figgy_auth_token"]
    response = connection.post("/resources/refresh_remote_metadata?auth_token=#{auth_token}") do |req|
      req.body = { archival_collection_codes: collection_ids }.to_json
    end

    raise FiggyError unless response.success?
  end
end
