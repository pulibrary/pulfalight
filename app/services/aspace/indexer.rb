# frozen_string_literal: true
class Aspace::Indexer
  def self.index_new
    new(client: Aspace::Client.new).index_new
  end

  def self.full_reindex
    new(client: Aspace::Client.new).full_reindex
  end

  attr_reader :client
  def initialize(client:)
    @client = client
  end

  def index_new
    reindex(modified: modified_since)
  end

  def full_reindex
    reindex(modified: nil)
  end

  def modified_since
    Event.where(name: "index").first&.updated_at&.to_i
  end

  private

  def reindex(modified:)
    client.ead_urls(modified_since: modified).each do |repository, urls|
      urls.each do |url|
        Rails.logger.info("Queued #{url} in repository #{repository} for indexing.")
        AspaceIndexJob.perform_later(resource_descriptions_uri: url, repository_id: repository)
      end
    end
    Event.find_or_create_by(name: "index").touch
  end
end
