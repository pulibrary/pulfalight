# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Arclight::SearchBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:remove_grouping, :boost_collections, :add_fields]

  def remove_grouping(solr_params)
    # Remove grouping parameters if faceting by collection
    Arclight::Engine.config.catalog_controller_group_query_params.keys.each { |k| solr_params.delete(k) } if blacklight_params.dig(:f, :collection_sim)
    solr_params
  end

  def boost_collections(solr_params)
    solr_params[:bq] ||= []
    solr_params[:bq] << "level_ssm:collection^20"
  end

  def add_fields(solr_params)
    solr_params[:qf] = [
      "ead_ssi^100",
      "collection_title_tesim^10",
      "physloc_tesim",
      "location_info_tesim",
      "containers_tesim",
      "physloc_tesim",
      "collection_title_tesim",
      "title_tesim",
      "name_tsim",
      "place_tsim",
      "unitid_identifier_match",
      "subject_tsim",
      "ref_identifier_match",
      "parent_identifier_match",
      "text"
    ]
    solr_params[:pf] = [
      "title_tesim^10",
      "name_tsim^10",
      "place_tsim^10",
      "subject_tsim^2"
    ]
    solr_params[:pf2] = [
      "location_info_tesim^20"
    ]
    solr_params[:ps2] = 3
    solr_params[:ps] = 3
    solr_params[:mm] = "0"
    boost_exact_matches(solr_params)
  end

  def boost_exact_matches(solr_params)
    return unless solr_params["q"]
    solr_params["q1"] = solr_params["q"]
    solr_params["boostQueryQf"] = "collection_title_tesim title_tesim^100"
    solr_params["bq"] << "_val_:\"{!edismax qf=$boostQueryQf mm=100% v=$q bq=}\"^100"
    # solr_params["bq1"] = "_query_:\"{!edismax v=$q1 mm='100%' qf='collection_tesim' fq='level_ssm:collection'}\"^100"
    # solr_params["q"] = "_query_:\"{!edismax v=$q1 bq=$bq1 mm='75%'}\""
    solr_params["uf"] = "_val_"
  end
end
