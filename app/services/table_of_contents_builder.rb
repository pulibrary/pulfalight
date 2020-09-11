# frozen_string_literal: true

class TableOfContentsBuilder
  def self.build(document, single_node: false)
    new(document, single_node: single_node).build
  end

  attr_reader :document, :single_node
  def initialize(document, single_node: false)
    @document = document
    @single_node = single_node
  end

  def build
    return toc_single_node if single_node
    toc_full
  end

  private

  def build_tree(solr_docs)
    return [] unless solr_docs
    # Ensure that the docs object is an array. Solr will return a single
    # hash rather than an array if there is a single component.
    solr_docs = Array.wrap(solr_docs)
    solr_docs.map do |doc|
      node = Tree::TreeNode.new(doc["id"], content(doc))
      children = build_tree(doc["components"])
      children.each do |child|
        node << child
      end

      node
    end
  end

  def collection_id
    document.fetch("parent_ssm", [document.id]).first
  end

  def content(component)
    {
      id: component["id"],
      text: component["normalized_title_ssm"].first,
      has_children: component["components"].present?
    }
  end

  def field_list
    "id, normalized_title_ssm, level_ssm, components, [child limit=1000000]"
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
    tree = build_tree(solr_doc).first
    prune_children(tree)

    # Transform child nodes into jqtree json document
    output = transform(tree.children)
    output.to_json
  end

  def toc_full
    solr_doc = solr_response(collection_id)
    tree = build_tree(solr_doc).first
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
      content[:state] = { selected: true } if content[:id] == document.id
      content.delete(:has_children)
      content.delete_if { |_k, v| v.nil? || v.blank? }
      content
    end
  end
end
