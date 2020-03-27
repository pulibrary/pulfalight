# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Arclight::SolrDocument

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  def collection?
    level_values = fetch(:level_ssm)
    return false if level_values.empty?

    level_values.first == 'collection'
  end

  def collection_document
    return self if collection?

    ead_id = fetch(:ead_ssi, "")
    return self unless ead_id

    response = Blacklight.default_index.search(q: "id:#{ead_id}", fl:'*')
    response_values = response['response']
    solr_documents = response_values['docs']
    return self if solr_documents.empty?

    solr_document = solr_documents.last
    self.class.new(solr_document)
  end

  def navigation_tree
    values = collection_document.fetch(:navigation_tree_tesim, [])
    return {} if values.empty?

    serialized = values.first
    JSON.parse(serialized)
  end
end
