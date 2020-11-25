# frozen_string_literal: true
class SolrDocumentTree
  class Node
    attr_reader :document, :children

    # Retrieve the current Solr index for querying
    # @return [Blacklight::Solr::Repository]
    def self.blacklight_index
      Blacklight.default_index
    end

    # Generate the Solr Child Document Transformer parameter for the query results
    # @return [Array<String>]
    def self.solr_child_doc_transformer
      ["child", "fl=id,normalized_title_ssm,scopecontent_ssm,extent_ssm,arrangement_ssm,component_level_isim", "limit=1000000"]
    end

    # Generate the Solr Document Transformers for the query results
    # @return [Array<Array<String>>]
    def self.solr_doc_transformers
      [solr_child_doc_transformer]
    end

    # Generate the necessary Solr Document fields
    # @return [Array<String>]
    def self.solr_fields
      ["id,normalized_title_ssm,scopecontent_ssm,extent_ssm,arrangement_ssm,components,level_ssm,component_level_isim"]
    end

    # Generate the field list parameter for the Solr Query
    # @return [String]
    def self.field_list
      values = solr_fields
      transformers = solr_doc_transformers.map { |dt| dt.join(" ") }.join(" ")
      values << "[#{transformers}]"
      values.join(" ")
    end

    # Retrieve the Document with the requested fields from Solr
    # @param document [SolrDocument]
    # @return [SolrDocument]
    def self.query_solr(document)
      solr_response = blacklight_index.find(document.id, fl: field_list)
      response = solr_response["response"]
      docs = response["docs"]
      docs.map { |doc| SolrDocument.new(doc) }
    end

    # Constructor
    # @param document [SolrDocument]
    def initialize(document)
      @document = document
      @children = find_children
    end

    private

    # Query for and build object child documents
    # @return [<SolrDocumentTree>]
    def find_children
      if @document.collection? && @document.component_documents.empty?
        retrieved_docs = self.class.query_solr(@document)
        return [] if retrieved_docs.empty?

        retrieved_doc = retrieved_docs.first
        return retrieved_doc.component_documents.map { |doc| self.class.new(doc) }
      end

      @document.component_documents.map { |doc| self.class.new(doc) }
    end
  end

  attr_reader :root

  # Constructor
  # @param root [SolrDocument]
  def initialize(root:)
    @root = root
  end

  # Build trees for each child node
  # @return [Array<SolrDocumentTree::Node>]
  def children
    root_node.children.map { |c| self.class.new(root: c.document) }
  end

  private

  # Build a tree node from the root SolrDocument
  # @return [SolrDocumentTree::Node]
  def root_node
    @root_node ||= Node.new(@root)
  end
end
