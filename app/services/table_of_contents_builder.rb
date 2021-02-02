# frozen_string_literal: true

class TableOfContentsBuilder
  def self.build(document, single_node: false, expanded: false)
    new(document, single_node: single_node, expanded: expanded).build
  end

  attr_reader :document, :single_node
  def initialize(document, single_node: false, expanded: false)
    @document = document
    @single_node = single_node
    @expanded = expanded
  end

  def build
    return toc_single_node if single_node
    toc_full
  end

  private

  def build_tree(solr_docs, level: 0, full: false)
    return [] unless solr_docs
    # Ensure that the docs object is an array. Solr will return a single
    # hash rather than an array if there is a single component.
    solr_docs = Array.wrap(solr_docs)
    solr_docs.map do |doc|
      node = Tree::TreeNode.new(doc["id"], content(doc, full: full, level: level))
      children = build_tree(doc["components"], level: level + 1, full: full)
      children.each do |child|
        node << child
      end

      node
    end
  end

  def collection_id
    document.fetch("parent_ssm", [document.id]).first
  end

  def component_level
    document.fetch("component_level_isim", ["0"]).first.to_i
  end

  def component_ancestry
    document.fetch("parent_ssm", [])
  end

  def content(component, level: 0, full: false)
    {
      id: component["id"],
      text: text(component),
      has_children: component["components"].present?,
      state: { opened: @expanded || (full && expand?(component, level)) } # This applies to every node in the tree
    }
  end

  def expand?(component, current_level)
    component["id"] == document["id"] || (component_ancestry.include?(component["id"]) && current_level < component_level + 1)
  end

  def text(component)
    title = component["normalized_title_ssm"].first
    return title unless component["has_online_content_ssim"]&.first == "true"
    "#{title} <span class=\"media-body al-online-content-icon\" aria-hidden=\"true\">#{ActionController::Base.helpers.blacklight_icon(:online)}</span>"
  end

  def field_list
    "id, normalized_title_ssm, level_ssm, components, has_online_content_ssim, [child limit=1000000]"
  end

  def find_node(root_node, id)
    root_node.breadth_each.find { |node| node.name == id }
  end

  def prune_children(node)
    node.children.each(&:remove_all!)
  end

  def prune_siblings(node)
    node.siblings.each(&:remove_all!)
    prune_siblings(node.parent) unless node.is_root?
  end

  def solr_response(id)
    Blacklight.default_index.find(id, fl: field_list)["response"]["docs"]
  end

  def toc_single_node
    solr_doc = solr_response(document.id)
    tree = build_tree(solr_doc, level: 0).first
    prune_children(tree)

    # Transform child nodes into jqtree json document
    output = transform(tree.children)
    output.to_json
  end

  def toc_full
    solr_doc = solr_response(collection_id)
    tree = build_tree(solr_doc, level: 0, full: true).first
    selected_node = find_node(tree, document.id)
    prune_children(selected_node)
    prune_siblings(selected_node)

    # Transform tree without top-level collection node into jqtree json document
    output = transform(tree.children)
    output.to_json
  end

  def transform(nodes)
    return [] unless nodes
    nodes.map do |node|
      content = node.content
      content[:children] = transform(node.children)
      content[:children] = true if content[:children].blank? && content[:has_children]

      if content[:id] == document.id
        node_state = content[:state]
        node_state = node_state.merge({ selected: true })
        content[:state] = node_state
      end

      content.delete(:has_children)
      content.delete_if { |_k, v| v.nil? || v.blank? }
      content
    end
  end
end
