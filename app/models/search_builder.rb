# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Arclight::SearchBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:remove_grouping, :boost_collections, :strip_quotes]

  # Boost weight for a collection who's title matches query
  COLLECTION_TITLE_BOOST_WEIGHT = 20

  def remove_grouping(solr_params)
    # Remove grouping parameters if faceting by collection
    Arclight::Engine.config.catalog_controller_group_query_params.keys.each { |k| solr_params.delete(k) } if blacklight_params.dig(:f, :collection_sim)
    solr_params
  end

  # Boost a collection only when the query matches its title
  def boost_collections(solr_params)
    solr_params[:bq] ||= []
    query = blacklight_params[:q]
    if query.present?
      # Stash the user's query in a new param. Needed so we can use the query value in
      # the boost without getting into an infinite loop.
      solr_params[:titleq] = query
      # Explanation:
      # `+level_ssm:collection` - matches collection documents. Required.
      # `+_query_` - nested sub-query for title. Required.
      # `qf=collection_title_tesim^20` - boost on title match.
      # `v=$titleq` - value of the stashed query to use in the title match.
      solr_params[:bq] << "+level_ssm:collection +_query_:\"{!simple qf=collection_title_tesim^#{COLLECTION_TITLE_BOOST_WEIGHT} v=$titleq}\""
    else
      # Keep collections above components when there is no keyword query
      solr_params[:bq] << "level_ssm:collection^#{COLLECTION_TITLE_BOOST_WEIGHT}"
    end

    solr_params
  end

  def strip_quotes(solr_params)
    return unless solr_params[:q]
    solr_params[:qs] = 2
  end

  # Override upstream highlighting method to add custom highlight field
  def add_highlighting(solr_params)
    solr_params["hl"] = true
    solr_params["hl.fl"] = "text_hl"
    solr_params["hl.snippets"] = 3
    solr_params
  end
end
