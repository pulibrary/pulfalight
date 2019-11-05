# frozen_string_literal: true

namespace :plantain do
  namespace :index do
    desc "Delete all Solr documents in the index"
    task :delete do
      delete_by_query("<delete><query>*:*</query></delete>")
    end

    desc "Index a single EAD file into Solr"
    task :document, [:file] do |_t, args|
      index_document(relative_path: args[:file])
    end

    desc "Index a directory of PULFA EAD files into Solr"
    task :collection, [:collection] do |_t, args|
      index_collection(name: args[:collection])
    end
  end

  desc "Run Solr and Arclight for interactive development"
  task :development do
    SolrWrapper.wrap(managed: true, verbose: true, port: 8983, instance_dir: "tmp/plantain-core-dev", persist: false, download_dir: "tmp") do |solr|
      solr.with_collection(name: "plantain-core-dev", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Setup solr"
        puts "Solr running at http://localhost:8983/solr/plantain-core-dev/, ^C to exit"
        begin
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    end
  end

  desc "Run Solr and Arclight for testing"
  task :test do |_t, _args|
    SolrWrapper.wrap(managed: true, verbose: true, port: 8984, instance_dir: "tmp/plantain-core-test", persist: false, download_dir: "tmp") do |solr|
      solr.with_collection(name: "plantain-core-test", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Setup solr"
        puts "Solr running at http://localhost:8984/solr/plantain-core-test/, ^C to exit"
        begin
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    end
  end

  desc "Seed fixture data to Solr"
  task :seed do
    puts "Seeding index with data from spec/fixtures/ead..."
    Dir.glob("spec/fixtures/ead/*.xml").each do |file|
      system("FILE=#{file} rake arclight:index") # no REPOSITORY_ID
    end

    Dir.glob("spec/fixtures/ead/*").each do |dir|
      next unless File.directory?(dir)

      repository_id = File.basename(dir)
      system("REPOSITORY_ID=#{repository_id} " \
             "REPOSITORY_FILE=config/repositories.yml " \
             "DIR=#{dir} " \
             "rake arclight:index_dir")
    end
  end

  # Utility methods

  # Construct a new Logger for STDOUT
  # @return [Logger]
  def logger
    @logger ||= Logger.new(STDOUT)
  end

  # Retrieve the connection to the Solr index for Blacklight
  # @return [RSolr]
  def blacklight_connection
    repository = Blacklight.default_index
    repository.connection
  end

  # Retrieve the URL for the Blacklight Solr core
  # @return [String]
  def blacklight_url
    blacklight_connection.base_uri
  rescue StandardError
    ENV["SOLR_URL"] || "http://127.0.0.1:8983/solr/blacklight-core"
  end

  # Delete a set of Solr Documents using a query
  # @param [String] query
  # @return [Boolean]
  def delete_by_query(query)
    blacklight_connection.update(data: query, headers: { "Content-Type" => "text/xml" })
    blacklight_connection.commit
  end

  # Query Solr for a single Document by the ID
  # @param [String] id
  # @return [Hash]
  def query_by_id(id:)
    response = blacklight_connection.get("select", params: { q: "id:\"#{id}\"", fl: "*", rows: 1 })
    docs = response["response"]["docs"]
    docs.first
  end

  # Retrieve the file path for the ArcLight core Traject configuration
  # @return [String]
  def arclight_config_path
    pathname = Rails.root.join("lib", "plantain", "traject", "ead2_config.rb")
    pathname.to_s
  end

  # Construct a Traject indexer object for building Solr Documents from EADs
  # @return [Traject::Indexer::NokogiriIndexer]
  def indexer
    indexer = Traject::Indexer::NokogiriIndexer.new
    indexer.tap do |i|
      i.load_config_file(arclight_config_path)
    end
  end

  # Search Solr for a Document corresponding to an EAD Document
  # @param [File] file
  # @return [Hash]
  def search_for_file(file)
    xml_doc = Nokogiri::XML(file)
    xml_doc.remove_namespaces!
    solr_document = indexer.map_record(xml_doc)
    query_by_id(id: solr_document["id"])
  end

  # Determines whether or not an EAD-XML Document has already been indexed in
  #   Solr
  # @param [String] file_path
  # @return [Boolean]
  def indexed?(file_path:)
    file = File.new(file_path)

    doc = search_for_file(file)
    doc.present?
  end

  # Generate the path for the EAD directory
  # @return [Pathname]
  def pulfa_root
    @pulfa_root ||= Rails.root.join("eads", "pulfa")
  end

  # Index an EAD-XML Document into Solr
  # @param [String] relative_path
  def index_document(relative_path:, root_path: nil)
    root_path ||= pulfa_root
    ead_file_path = File.join(root_path, relative_path)
    IndexJob.perform_later([ead_file_path])
  end

  # Index a directory of PULFA EAD-XML Document into Solr
  # Note: This assumes that the documents have been checked out into eads/pulfa
  # @param [String] relative_path
  def index_collection(name:, root_path: nil)
    root_path ||= pulfa_root
    dir = root_path.join(name)
    glob_pattern = File.join(dir, "**", "*.xml")
    file_paths = Dir.glob(glob_pattern)

    file_paths.each_slice(1) do |file_path_subset|
      IndexJob.perform_later(file_path_subset)
    end
  end
end
