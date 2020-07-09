# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  include Arclight::SolrDocument
  include ActiveModel::Serialization

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

  COLLECTION_LEVEL = "collection"

  # The attributes which are rendered by the JSON serialization
  # @return [Array<Symbol>]
  def self.json_attributes
    [
      :id,
      :unittitle,
      :has_digital_content,
      :components
    ]
  end

  def components
    fetch(:components, [])
  end

  def component_documents
    components.map { |component_values| self.class.new(component_values) }
  end

  def component_attributes
    component_documents.map(&:attributes)
  end

  def level
    values = fetch(:level_ssm, [])
    values.first
  end

  def collection?
    return false if level.nil?

    level == self.class::COLLECTION_LEVEL
  end

  def component?
    key?("component_level_isim")
  end

  def html_presenter_class
    if component?
      ComponentHtmlPresenter
    else
      CollectionHtmlPresenter
    end
  end

  def html_presenter
    html_presenter_class.new(self)
  end
  alias presenter html_presenter # Update this for other format-based presenters

  def id
    Array.wrap(super).first
  end

  def refs
    fetch("ref_ssm", [])
  end

  def ead
    fetch("ead_ssi", [])
  end

  def eadid
    Array.wrap(super).first
  end

  def collection_notes
    fetch("collection_notes_ssm", [])
  end

  def title
    fetch("title_ssm", [])
  end
  alias unittitle title

  def places
    fetch("places_ssm", [])
  end

  def access_subjects
    fetch("access_subjects_ssm", [])
  end

  def acqinfo
    fetch("acqinfo_ssm", [])
  end

  def scopecontent
    fetch("scopecontent_ssm", [])
  end

  def parent
    fetch("parent_ssm", [])
  end

  def abstract
    fetch("abstract_ssm", [])
  end

  def collection
    fetch("collection_ssm", [])
  end

  def names
    fetch("names_ssim", [])
  end

  def corpname
    fetch("corpname_ssm", [])
  end

  def geogname
    fetch("geogname_ssm", [])
  end

  def has_online_content
    fetch("has_online_content_ssim", [])
  end

  def has_digital_content?
    has_online_content.present?
  end

  def attributes
    default_attributes = {}
    merged = default_attributes.merge(blacklight_attributes)
    merged = merged.merge(arclight_attributes)
    merged = merged.merge(pulfalight_attributes)
    merged.select { |u, _v| self.class.json_attributes.include?(u) }
  end
  delegate :to_json, to: :attributes

  private

    def pulfalight_attributes
      {
        has_digital_content: has_digital_content?,
        components: component_attributes,
        containers: containers,
        refs: refs,
        ead: ead,
        title: title,
        unittitle: title,
        collection: collection,
        names: names,
        corpname: corpname,
        geogname: geogname,
        places: places,
        access_subjects: access_subjects,
        acqinfo: acqinfo,
        scopecontent: scopecontent
      }
    end

    def arclight_attributes
      {
        level: level,
        component_level: component_level,
        reference: reference,
        creator: creator,
        abstract: abstract,
        extent: extent,
        repository: repository,
        unitid: unitid,
        eadid: eadid,
        parent: parent,
        parent_levels: parent_levels,
        parent_labels: parent_labels,
        parent_ids: parent_ids
      }
    end

    def blacklight_attributes
      {
        id: id
      }
    end
end
