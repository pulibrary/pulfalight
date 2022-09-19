# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Arclight::SearchBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:remove_grouping, :boost_collections, :strip_quotes, :filter_unpublished]

  def remove_grouping(solr_params)
    # Remove grouping parameters if faceting by collection
    Arclight::Engine.config.catalog_controller_group_query_params.keys.each { |k| solr_params.delete(k) } if blacklight_params.dig(:f, :collection_sim)
    solr_params
  end

  def boost_collections(solr_params)
    solr_params[:bq] ||= []
    solr_params[:bq] << "level_ssm:collection^20"
  end

  def strip_quotes(solr_params)
    return unless solr_params[:q]
    solr_params[:qs] = 2
  end

  def filter_unpublished(solr_params)
    solr_params[:fq] ||= []
    solr_params[:fq] << "-audience_ssi:internal"
  end

  # Override upstream highlighting method to add custom highlight field
  def add_highlighting(solr_params)
    solr_params["hl"] = true
    solr_params["hl.fl"] = "text_hl"
    solr_params["hl.snippets"] = 3
    solr_params
  end
end
