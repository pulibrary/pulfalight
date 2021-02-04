# frozen_string_literal: true
class Aspace::Indexer
  def self.index_new
    new(client: Aspace::Client.new).index_new
  end

  attr_reader :client
  def initialize(client:)
    @client = client
  end

  def index_new
    client.ead_urls(modified_since: modified_since).each do |repository, urls|
      urls.each do |url|
        Rails.logger.info("Queued #{url} in repository #{repository} for indexing.")
        AspaceIndexJob.perform_later(resource_descriptions_uri: url, repository_id: repository)
      end
    end
    Event.find_or_create_by(name: "index").touch
  end

  def modified_since
    Event.where(name: "index").first&.updated_at&.to_i
  end
end
