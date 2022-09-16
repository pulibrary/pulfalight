# frozen_string_literal: true
require "./lib/pulfalight/missing_repository_error"

# Asynchronous job used to index EAD Documents
class AspaceIndexJob < ApplicationJob
  # Class for capturing the output of the Traject indexer
  class EADArray < Array
    # Appends the output of the Traject indexer
    # (Used by Traject#foo)
    # @param context [Traject::Context]
    def put(context)
      push(context.output_hash)
    end
  end

  # Retrieve the file path for the ArcLight core Traject configuration
  # @return [String]
  def arclight_config_path
    pathname = Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb")
    pathname.to_s
  end

  # Construct a Traject indexer object for building Solr Documents from EADs
  # @return [Traject::Indexer::NokogiriIndexer]
  def indexer
    indexer = Traject::Indexer::NokogiriIndexer.new(repository: @repository_id)
    indexer.tap do |i|
      i.load_config_file(arclight_config_path)
    end
  end

  # Retrieve the connection to the Solr index for Blacklight
  # @return [RSolr]
  def blacklight_connection
    repository = Blacklight.default_index
    repository.connection
  end

  def logger
    Rails.logger || Logger.new(STDOUT)
  end

  def aspace_client
    @aspace_client ||= Aspace::Client.new
  end

  def perform(resource_descriptions_uri:, repository_id: nil, soft: false, sync_to_figgy: false)
    ead_content = aspace_client.get_resource_description_xml(resource_descriptions_uri: resource_descriptions_uri, cached: soft)
    xml_documents = Nokogiri::XML.parse(ead_content)
    xml_documents.remove_namespaces!

    @repository_id = repository_id.try(&:downcase)
    solr_documents = EADArray.new

    logger.info("Transforming the Documents for Solr...")
    indexer.process_with([xml_documents], solr_documents)

    logger.info("Requesting a batch Solr update...")
    blacklight_connection.add(solr_documents)
    logger.info("Successfully indexed the EAD")

    SyncToFiggyJob.perform_later(solr_documents.flat_map { |doc| doc["id"] }) if sync_to_figgy
  rescue Pulfalight::MissingRepositoryError
    Honeybadger.notify("An Arclight::Repository was not found for repository_id #{repository_id} when indexing #{resource_descriptions_uri}. Check configuration in config/repositories.yml")
  end
end
