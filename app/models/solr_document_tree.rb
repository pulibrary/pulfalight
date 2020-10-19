# frozen_string_literal: true
class SolrDocumentTree
  class Node
    attr_reader :document

    def initialize(document)
      @document = document
    end

    def children
      @children ||= find_children
    end

    def descendents
      @descendents ||= find_descendents
    end

    def self.blacklight_index
      Blacklight.default_index
    end

    def self.solr_client
      blacklight_index.connection
    end

    def self.field_list
      "*, components, [child fl=* limit=1000000]"
    end

    def self.find_children_query(document)
      "id:#{document.id}"
    end

    def self.query_solr(query)
      server_response = solr_client.select(params: { q: query, fl: field_list })
      solr_response = server_response["response"]
      docs = solr_response["docs"]
      docs.map { |doc| SolrDocument.new(doc) }
    end

    def find_children
      if @document.key?("components")
        components = Array.wrap(@document["components"])
      else
        query = self.class.find_children_query(@document)
        parent_docs = self.class.query_solr(query)
        return [] if parent_docs.empty?

        parent_doc = parent_docs.first
        components = Array.wrap(parent_doc["components"])
      end

      docs = components.map { |p| SolrDocument.new(p) }
      docs.map { |doc| self.class.new(doc) }
    end

    def find_descendents
      nodes = []

      children.each do |child|
        nodes << child
        nodes += child.find_descendents
      end

      nodes
    end
  end

  def initialize(root:)
    @root = root
  end

  def document
    @root
  end

  def root_node
    @root_node ||= Node.new(@root)
  end

  def children
    root_node.children.map { |c| self.class.new(root: c.document) }
  end

  def descendent_documents
    root_node.descendents.map(&:document)
  end
end
