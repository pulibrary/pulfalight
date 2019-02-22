# frozen_string_literal: true
require 'csv'
require_relative '../pulfa'

namespace :pulfa do
  def load_indexer
    ENV['SOLR_URL'] ||= Blacklight.default_index.connection.uri.to_s

    options = {
      document: Pulfa::CustomDocument,
      component: Pulfa::CustomComponent
    }

    Pulfa::Indexer.new(options)
  end

  namespace :index do
    desc 'Index an EAD document, use FILE=<path/to/ead.xml> and REPOSITORY_ID=<myid>'
    task :file do
      raise 'Please specify your EAD document, ex. FILE=<path/to/ead.xml>' unless ENV['FILE']
      indexer = load_indexer
      print "Loading #{ENV['FILE']} into index...\n"
      indexer.update(ENV['FILE'])
    end

    desc 'Delete all Solr documents in the index'
    task :delete do
      delete_by_query('<delete><query>*:*</query></delete>')
    end

    desc 'Index a collection of EAD Documents'
    task :collection, [:collection_name] => :environment do |_t, args|
      index_collection(name: args.collection_name)
    end

    desc 'Index a set of EAD Documents specified in the configuration'
    task :set do
      index_set
    end

    desc 'Index a single EAD Document'
    task :document, [:file_path, :repo] => :environment do |_t, args|
      index_document(relative_path: args.file_path, repo: args.repo)
    end

    desc 'Index test fixtures'
    task :fixtures => :environment do |_t, args|
      index_collection(name: 'eng', root_path: fixtures_path)
      index_collection(name: 'lae', root_path: fixtures_path)
      index_collection(name: 'mss', root_path: fixtures_path)
      index_collection(name: 'mudd', root_path: fixtures_path)
      index_collection(name: 'rarebooks', root_path: fixtures_path)
    end
  end

  def fixtures_path
    Rails.root.join('spec', 'fixtures', 'files', 'ead')
  end

  desc 'Index the EAD XML Documents from PULFA 2.0'
  task :index do
    pulfa_collections.each do |collection_name|
      index_collection(name: collection_name)
    end
  end

  desc 'Run Solr and Arclight for interactive development'
  task :development, %i[rails_server_args] do |_t, args|
    SolrWrapper.wrap(managed: true, verbose: true, port: 8983, instance_dir: "tmp/pulfa-core-dev", persist: false, download_dir: "tmp") do |solr|
      solr.with_collection(name: "pulfa-core-dev", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Setup solr"
        puts "Solr running at http://localhost:8983/solr/pulfa-core-dev/, ^C to exit"
        begin
          system "bundle exec rails s #{args[:rails_server_args]}"
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    end
  end

  desc 'Run Solr and Arclight for testing'
  task :test do |_t, _args|
    SolrWrapper.wrap(managed: true, verbose: true, port: 8984, instance_dir: "tmp/pulfa-core-test", persist: false, download_dir: "tmp") do |solr|
      solr.with_collection(name: "pulfa-core-test", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Setup solr"
        puts "Solr running at http://localhost:8984/solr/pulfa-core-test/, ^C to exit"
        begin
          sleep
        rescue Interrupt
          puts "\nShutting down..."
        end
      end
    end
  end

  desc 'Seed fixture data to Solr'
  task :seed do
    puts 'Seeding index with data from spec/fixtures/ead...'
    Dir.glob('spec/fixtures/ead/*.xml').each do |file|
      system("FILE=#{file} rake arclight:index") # no REPOSITORY_ID
    end
    Dir.glob('spec/fixtures/ead/*').each do |dir|
      next unless File.directory?(dir)
      system("REPOSITORY_ID=#{File.basename(dir)} " \
             'REPOSITORY_FILE=config/repositories.yml ' \
             "DIR=#{dir} " \
             'rake arclight:index_dir')
    end
  end

  #### Methods

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  # Index a collection using its name
  # @param name [String]
  # @param root_path [Pathname]
  def index_collection(name:, root_path: nil)
    root_path ||= pulfa_root
    dir = root_path.join(name)
    ENV['REPOSITORY_ID'] = name.split('/').first

    Dir.glob(File.join(dir, '**', '*.xml')).each do |file_path|
      ENV['FILE'] = file_path

      logger.info "Indexing #{file_path}..."
      # This catches both EAD-XML parsing and indexing errors
      begin
        if indexed?(file_path: file_path)
          logger.info "Already indexed #{file_path}"
          next
        end

        Rake::Task['pulfa:index:file'].invoke
      rescue StandardError => arclight_error
        logger.error "Failed to index #{file_path}: #{arclight_error}"
      end
    end
  end

  def configured_index_set
    rows = CSV.read(Rails.root.join("index_set.csv"))
    rows[1..-1]
  end

  def index_set
    configured_index_set.each do |row|
      relative_path = row.first
      repo = row.last
      index_document(relative_path: relative_path, repo: repo)
    end
  end

  def index_document(relative_path:, repo:)
    file_path = File.absolute_path(relative_path)
    ENV['REPOSITORY_ID'] = repo
    ENV['FILE'] = file_path

    logger.info "Indexing #{file_path}..."
    # This catches both EAD-XML parsing and indexing errors
    begin
      if indexed?(file_path: file_path)
        logger.info "Already indexed #{file_path}"
        return
      end

      Rake::Task['pulfa:index:file'].invoke
    rescue StandardError => arclight_error
      logger.error "Failed to index #{file_path}: #{arclight_error}"
    end
  end

  # Generate the path for the EAD directory
  # @return [Pathname]
  def pulfa_root
    @pulfa_root ||= Rails.root.join('eads', 'pulfa', 'eads')
  end

  # Construct the directory for the root directory
  # @return [Dir]
  def pulfa_dir
    @pulfa_dir ||= Dir.new(pulfa_root)
  end

  def pulfa_collections
    return @pulfa_collections unless @pulfa_collections.nil?

    dirs = Dir.entries(pulfa_dir).select { |entry| File.directory?(pulfa_root.join(entry)) }
    @pulfa_collections = dirs.reject { |dir_path| /^\./.match(dir_path) }
  end

  def blacklight_connection
    repository = Blacklight.default_index
    repository.connection
  end

  def delete_by_query(query)
    blacklight_connection.update(data: query, headers: { 'Content-Type' => 'text/xml' })
    blacklight_connection.commit
  end

  def query_by_id(id:)
    response = blacklight_connection.get("select", params: { q: "id:\"#{id}\"", fl: "*", rows: 1 })
    docs = response["response"]["docs"]
    docs.first
  end

  def search_by_id(id:)
    query_by_id(id: id)
  end

  def build_document(file)
    Arclight::CustomDocument.from_xml(file)
  end

  def search_for_file(file)
    document = build_document(file)
    solr_document = document.to_solr
    search_by_id(id: solr_document['id'])
  end

  def indexed?(file_path:)
    file = File.new(file_path)

    doc = search_for_file(file)
    doc.present?
  end
end
