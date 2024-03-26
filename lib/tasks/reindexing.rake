# frozen_string_literal: true
namespace :pulfalight do
  namespace :indexing do
    desc "Run an incremental reindex"
    task incremental: :environment do
      default_logger = ENV["DEFAULT_LOGGER"] == "true"
      Rails.logger = Logger.new(STDOUT) unless default_logger
      Aspace::Indexer.index_new
    end
    task full: :environment do
      default_logger = ENV["DEFAULT_LOGGER"] == "true"
      Rails.logger = Logger.new(STDOUT) unless default_logger
      Aspace::Indexer.full_reindex
    end
    task soft_full: :environment do
      Rails.logger = Logger.new(STDOUT)
      Aspace::Indexer.soft_full_reindex
    end
  end
end
