# frozen_string_literal: true

class TreeNavigationService
  def self.logger
    Rails.logger || Logger.new(STDOUT)
  end

  def self.build(solr_document)
    tree = {}

    collection_ids = solr_document["id"]
    collection_id = collection_ids.first
    components = solr_document["components"]

    # Empty the components
    solr_document["components"] = nil

    # Set the children to empty
    solr_document["children"] = []
    tree["root"] = solr_document
    tree[collection_id] = tree["root"]

    components.each do |component|
      logger.info "Processing #{component['id']}"

      parent_ids = component["parent_ssi"]
      parent_id = parent_ids.first

      component_ids = component["id"]
      component_id = component_ids.first

      if parent_id == collection_id
        tree[collection_id]["children"] << component

        parent_document = solr_document.clone
        parent_document["children"] = []
        component["parents"] = [parent_document]
      else
        # This assumes that the document is being parsed in order
        parent_document = tree[parent_id]
        tree[parent_id]["children"] = tree[parent_id]["children"] || []
        tree[parent_id]["children"] << component

        parent_document = tree[parent_id].clone
        parent_document["children"] = []
        parent_document["parents"] = []
        component["parents"] = [parent_document]
      end
      tree[component_id] = component
    end

    tree
  end
end
