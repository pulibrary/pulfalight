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

    desc 'Delete the index of all EADs'
    task :delete do
      delete_by_query('<delete><query>*:*</query></delete>')
    end

    desc 'Index a collection'
    task :collection, [:collection_name] => :environment do |t, args|
      index_collection(name: args.collection_name)
    end

    task :document, [:file_path, :repo] => :environment do |t, args|
      index_document(relative_path: args.file_path, repo: args.repo)
    end
  end

  desc 'Index the EAD XML Documents from PULFA 2.0'
  task :index do
    pulfa_collections.each do |collection_name|
      index_collection(name: collection_name)
    end
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def index_collection(name:)    
    dir = pulfa_root.join(name)
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

  def pulfa_root
    @pulfa_root ||= Rails.root.join('eads', 'pulfa', 'eads')
  end

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
