# frozen_string_literal: true
class TocController < ApplicationController
  def toc
    render json: TableOfContentsBuilder.build(document, single_node: single_node?, expanded: expanded?)
  rescue Blacklight::Exceptions::RecordNotFound
    render json: {}
  end

  def child_table
    render json: ChildTableBuilder.new(params[:node]).to_a
  end

  private

  def document
    SolrDocument.find(params[:node])
  end

  def single_node?
    return false if params[:full] == "true"
    true
  end

  def expanded?
    params[:expanded] == "true"
  end
end
