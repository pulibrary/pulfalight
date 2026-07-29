# frozen_string_literal: true

class FiggyReportService
  class FiggyError < StandardError; end

  def self.fetch_figgy_lookup(collection_id)
    auth_token = Pulfalight.config["figgy_auth_token"]
    return {} unless auth_token

    connection = Faraday.new(
      url: Pulfalight.config["figgy_url"],
      headers: { "Content-Type" => "application/json" }
    )
    response = connection.get("/reports/pulfalight_records?collection=#{collection_id}&auth_token=#{auth_token}")

    raise FiggyError unless response.success?

    JSON.parse(response.body)
  end
end
