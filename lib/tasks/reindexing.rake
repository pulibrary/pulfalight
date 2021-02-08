# frozen_string_literal: true
namespace :pulfalight do
  namespace :indexing do
    desc "Run an incremental reindex"
    task incremental: :environment do
      Rails.logger = Logger.new(STDOUT)
      Aspace::Indexer.index_new
    end
    task full: :environment do
      Rails.logger = Logger.new(STDOUT)
      Aspace::Indexer.full_reindex
    end
  end
end
