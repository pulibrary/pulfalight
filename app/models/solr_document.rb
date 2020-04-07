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

  def child_tree
    @child_tree ||=
      begin
        grouped_components = collection_components.group_by { |x| x["parent_ssm"].last }
        top_level = grouped_components[collection_id]
        map_children(grouped_components, top_level)
      end
  end

  def map_children(all_components, sub_group)
    sub_group.map do |node|
      if all_components[node["id"]].present?
        { id: node["id"], title: node["title_ssm"].first, children: map_children(all_components, all_components[node["id"]]) }
      else
        { id: node["id"], title: node["title_ssm"].first }
      end
    end
  end

  def collection_components
    @components ||=
      begin
        Blacklight.default_index.find(collection_id, fl: "title_ssm, id, component_level_isim, parent_ssm, components, [child limit=1000000]")["response"]["docs"][0]["components"]
      end
  end

  def collection_id
    fetch("parent_ssm", [id]).first
  end
end
