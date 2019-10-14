# frozen_string_literal: true

namespace :plantain do
  namespace :index do
    desc 'Delete all Solr documents in the index'
    task :delete do
      delete_by_query('<delete><query>*:*</query></delete>')
    end
  end

  desc 'Run Solr and Arclight for interactive development'
  task :development, %i[rails_server_args] do |_t, args|
    SolrWrapper.wrap(managed: true, verbose: true, port: 8983, instance_dir: "tmp/plantain-core-dev", persist: false, download_dir: "tmp") do |solr|
      solr.with_collection(name: "plantain-core-dev", dir: Rails.root.join("solr", "conf").to_s) do
        puts "Setup solr"
        puts "Solr running at http://localhost:8983/solr/plantain-core-dev/, ^C to exit"
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

  # Utility methods
  def blacklight_connection
    repository = Blacklight.default_index
    repository.connection
  end

  def delete_by_query(query)
    blacklight_connection.update(data: query, headers: { 'Content-Type' => 'text/xml' })
    blacklight_connection.commit
  end
end
