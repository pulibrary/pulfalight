# frozen_string_literal: true
class ChildTableBuilder
  attr_reader :id
  def initialize(id)
    @id = id
  end

  def to_a
    child_documents.map do |document|
      map_document(document)
    end
  end

  def child_documents
    @child_documents ||= solr_response.map do |response|
      SolrDocument.new(response)
    end
  end

  def map_document(document)
    {
      id: document.id,
      title: {
        value: Array.wrap(document.title).join(", "),
        link: Rails.application.routes.url_helpers.solr_document_url(id: document.id)
      },
      online: OnlineContentBadge.new(document).render,
      date: Array.wrap(document.date_created).join(", "),
      container: Array.wrap(document.container).join(", "),
      form_params: document.aeon_request.form_attributes,
      requestable: document.aeon_request.requestable?,
      location: document.aeon_request.location_attributes
    }
  end

  def solr_response
    Blacklight.default_index.search(q: "parent_ssi:#{id}", fl: "*", rows: 100_000)["response"]["docs"]
  end
end
