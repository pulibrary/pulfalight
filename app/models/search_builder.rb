# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Arclight::SearchBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  self.default_processor_chain += [:boost_collections, :strip_quotes]

  def boost_collections(solr_params)
    solr_params[:bq] ||= []
    solr_params[:bq] << "level_ssm:collection^20"
  end

  def strip_quotes(solr_params)
    return unless solr_params[:q]
    solr_params[:q] = solr_params[:q].tr('"', "")
  end
end
