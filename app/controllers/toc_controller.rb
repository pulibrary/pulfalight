# frozen_string_literal: true
class TocController < ApplicationController
  def toc
    render json: TableOfContentsBuilder.build(document, single_node: single_node?)
  rescue Blacklight::Exceptions::RecordNotFound
    render json: {}
  end

  private

  def document
    SolrDocument.find(params[:node])
  end

  def single_node?
    return false if params[:full] == "true"
    true
  end
end
