# frozen_string_literal: true
class TocController < ApplicationController
  def toc
    render json: TableOfContentsBuilder.build(document, single_node: single_node?, expanded: expanded?, online_content: online_content?)
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

  def online_content?
    params[:online_content] == "true"
  end
end
