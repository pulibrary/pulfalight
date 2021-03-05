# frozen_string_literal: true

require Rails.root.join("app", "jobs", "application_job")
require Rails.root.join("app", "jobs", "index_job")
require Rails.root.join("app", "services", "robots_generator_service")

namespace :pulfalight do
  namespace :aspace do
    desc "Index EADIDs defined by stakeholders as representatives."
    task index_test_eads: :environment do
      test_eadids = [
        "WC064",
        "C0614",
        "MC152",
        "C0807",
        "MC001.04",
        "C0776",
        "C0879",
        "AC019",
        "C0014",
        "MC001.03.01",
        "C0003",
        "RBD2",
        "AC014",
        "C0280",
        "MC039",
        "AC011",
        "C0171",
        "LAE026",
        "MC001.02.01",
        "ST1",
        "TC022",
        "C0003",
        "AC020",
        "MC085",
        "AC465",
        "MC181.05",
        "C1491",
        "AC003",
        "C0022",
        "MC001.02.01",
        "RBD1.1",
        "AC026",
        "C0247",
        "MC001.01",
        "C0001",
        "COTSEN5",
        "MC120",
        "RBD1.1",
        "AC001",
        "C0002",
        "ENG002",
        "LAE049",
        "MC001.02",
        "RBD3",
        "AC005",
        "C0006",
        "COTSEN1",
        "LAE002",
        "MC001.01",
        "RCPXR-6386581",
        "ST1",
        "AC010",
        "C0003",
        "LAE002",
        "MC001.02.06",
        "RCPXG-5830371.1",
        "TC022",
        "AC001",
        "C0022",
        "COTSEN1",
        "ENG001",
        "GC185",
        "LAE001",
        "MC001.01",
        "RCPXR-6386581",
        "AC001",
        "C0003",
        "COTSEN2",
        "ENG001",
        "GC186",
        "LAE001",
        "MC001.01",
        "RBD1.1",
        "C1387"
      ].uniq
      or_query = test_eadids.join(" OR ")
      client = Aspace::Client.new
      client.repositories.each do |repository|
        repository_uri = repository["uri"][1..-1]
        repo_code = repository["repo_code"]
        uris = client.get("#{repository_uri}/search", query: { q: "identifier:(#{or_query})", type: ["resource"], fields: ["uri"], page: 1 }).parsed["results"].map { |x| x["uri"] }
        uris.each do |uri|
          AspaceIndexJob.perform_later(resource_descriptions_uri: uri[1..-1].gsub("resources", "resource_descriptions"), repository_id: repo_code.split("-").first)
        end
      end
    end
  end
  namespace :fixtures do
    desc "Regenerate JSON fixtures from EAD"
    task regenerate_json: :environment do
      indexer = Traject::Indexer::NokogiriIndexer.new(repository: "publicpolicy").tap do |i|
        i.load_config_file(Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb"))
      end
      fixture_file = File.read(Rails.root.join("spec", "fixtures", "aspace", "mss", "C1588.xml"))
      nokogiri_reader = Arclight::Traject::NokogiriNamespacelessReader.new(fixture_file.to_s, indexer.settings)
      File.open(Rails.root.join("spec", "fixtures", "C1588.json"), "w") do |f|
        f.puts indexer.map_record(nokogiri_reader.to_a.first).to_json
      end
    end

    desc "Pulls Aspace EAD Fixtures"
    task refresh_aspace_fixtures: :environment do
      Rails.logger = Logger.new(STDOUT)
      AspaceFixtureGenerator.new.regenerate!
    end
  end
  namespace :index do
    desc "Delete all Solr documents in the index"
    task delete: :environment do
      delete_by_query("<delete><query>*:*</query></delete>")
    end

    desc "Index a single EAD file into Solr"
    task :file, [:file] => :environment do |_t, args|
      $stdout.puts "Indexing #{args[:file]}..."
      enqueue = ENV["ENQUEUE"] == "false" ? false : true
      index_file(relative_path: args[:file], root_path: Rails.root, enqueue: enqueue)
    end

    desc "Index a directory of PULFA EAD files into Solr"
    task :directory, [:directory] => :environment do |_t, args|
      index_directory(name: args[:directory])
    end

    namespace :configs do
      desc "Updates solr config files from github"
      task :update, [:solr_dir] => :environment do |_t, args|
        solr_dir = args[:solr_dir] || Rails.root.join("solr")

        ["_rest_managed.json", "admin-extra.html", "elevate.xml",
         "mapping-ISOLatin1Accent.txt", "protwords.txt", "schema.xml",
         "scripts.conf", "solrconfig.xml", "spellings.txt", "stopwords.txt",
         "stopwords_en.txt", "synonyms.txt"].each do |file|
          response = Faraday.get url_for_file(file)
          File.open(File.join(solr_dir, "conf", file), "wb") { |f| f.write(response.body) }
        end
      end
    end
  end

  namespace :server do
    task initialize: :environment do
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["pulfalight:seed"].invoke
    end

    desc "Start solr and postgres servers using lando."
    task start: :environment do
      system("lando start")
      system("rake pulfalight:server:initialize")
      system("rake pulfalight:server:initialize RAILS_ENV=test")
    end

    desc "Stop lando solr and postgres servers."
    task stop: :environment do
      system("lando stop")
    end
  end

  desc "Seed fixture data to Solr"
  task seed: :environment do
    puts "Seeding index with data from spec/fixtures/aspace/generated..."
    # Delete previous fixtures. Needed for lando-based test solr.
    delete_by_query("<delete><query>*:*</query></delete>")
    index_directory(name: "spec/fixtures/aspace/generated/", root_path: Rails.root, enqueue: false)
  end

  desc "Generate a robots.txt file"
  task robots_txt: :environment do |_t, args|
    file_path = args[:file_path] || Rails.root.join("public", "robots.txt")
    robots = RobotsGeneratorService.new(path: file_path, disallowed_paths: Rails.configuration.robots.disallowed_paths)
    robots.insert_group(user_agent: "*")
    robots.insert_crawl_delay(10)
    robots.insert_sitemap(Rails.configuration.robots.sitemap_url)
    robots.generate
    robots.write
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
    pathname = Rails.root.join("lib", "pulfalight", "traject", "ead2_config.rb")
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

  # Resolves the repository based upon the file path of a PULFA EAD file
  # @return [String]
  def resolve_repository_id(file_path)
    parent_path = File.expand_path("..", file_path)
    File.basename(parent_path)
  end

  # Index an EAD-XML Document into Solr
  # @param [String] relative_path
  def index_file(relative_path:, root_path: nil, enqueue: true)
    root_path ||= pulfa_root
    ead_file_path = if File.exist?(relative_path)
                      relative_path
                    else
                      File.join(root_path, relative_path)
                    end
    repository_id = resolve_repository_id(ead_file_path)

    if enqueue
      IndexJob.perform_later(file_paths: [ead_file_path], repository_id: repository_id)
    else
      IndexJob.perform_now(file_paths: [ead_file_path], repository_id: repository_id)
    end
  end

  # Index a directory of PULFA EAD-XML Document into Solr
  # Note: This assumes that the documents have been checked out into eads/pulfa
  # @param [String] relative_path
  def index_directory(name:, root_path: nil, enqueue: true)
    root_path ||= pulfa_root
    dir = root_path.join(name)
    glob_pattern = File.join(dir, "**", "*.xml")
    file_paths = Dir.glob(glob_pattern)

    file_paths.each do |file_path|
      # Don't index full versions of seed files if given argument.
      next if file_path.include?(".processed") && file_path.include?("MC221")
      # Index all of MC221 - we have several tests for it.
      # Several EAD seeds are "processed" to only contain the components needed
      # for indexing tests, to speed them up. MC221 is too, but we need the full
      # EAD for catalog tests. This processing happens in AspaceFixtureGenerator
      next if File.exist?(file_path.gsub(".EAD", ".processed.EAD")) && !file_path.include?("MC221")
      index_file(relative_path: file_path, root_path: root_path, enqueue: enqueue)
    end
    Blacklight.default_index.connection.commit
  end

  def solr_conf_dir
    Rails.root.join("solr", "conf").to_s
  end

  def url_for_file(file)
    "https://raw.githubusercontent.com/pulibrary/pul_solr/master/solr_configs/pulfalight-staging/conf/#{file}"
  end
end
