# frozen_string_literal: true
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
    @aspace_client ||=
      begin
        config = ArchivesSpace::Configuration.new({
          base_uri: Pulfalight.config["archivespace_url"],
          username: Pulfalight.config["archivespace_user"],
          password: Pulfalight.config["archivespace_password"],
          page_size: 50,
          throttle: 0
        })
        client = ArchivesSpace::Client.new(config).login
      end
  end

  def perform(collection_id:, repository_id:)
    aspace_client.config.base_repo = "repositories/#{repository_id}"
    ead_content = aspace_client.get("/resource_descriptions/#{collection_id}.xml", query: {include_daos: true}).body.force_encoding('UTF-8')
    xml_documents = Nokogiri::XML.parse(ead_content)
    xml_documents.remove_namespaces!

    # @repository_id = repository_id
    solr_documents = EADArray.new

    logger.info("Transforming the Documents for Solr...")
    indexer.process_with([xml_documents], solr_documents)

    logger.info("Requesting a batch Solr update...")
    blacklight_connection.add(solr_documents)
    logger.info("Successfully indexed the EAD")
  end
end
