# frozen_string_literal: true
# Asynchronous job used to index EAD Documents
class IndexParentJob < ApplicationJob
  # Retrieve the connection to the Solr index for Blacklight
  # @return [RSolr]
  def blacklight_connection
    repository = Blacklight.default_index
    repository.connection
  end

  def tree_navigation_service
    TreeNavigationService
  end

  def build_navigation_tree(solr_document)
    tree_navigation_service.build(solr_document)
  end

  def find_collection_solr_document(eadid)
    solr_response = Blacklight.default_index.search(q: "id:#{eadid}", fl: "id,navigation_tree_tesim")
    response = solr_response["response"]
    docs = response["docs"]
    docs.last
  end

  def perform(component_json)
    component = JSON.parse(component_json)
    component_ids = Array.wrap(component["id"])
    component_id = component_ids.first

    ead_id = component["ead_ssi"]
    collection_solr_document = find_collection_solr_document(ead_id)
    component["navigation_tree_tesim"] = collection_solr_document["navigation_tree_tesim"]

    blacklight_connection.delete_by_query("id:#{component_id}")
    blacklight_connection.add(component)
  end
end
