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
  # use_extension(Blacklight::Document::DublinCore)
  SolrDocument.use_extension(Pulfalight::Document::XMLExport)

  COLLECTION_LEVEL = "collection"
  ROOT_COMPONENT_LEVEL = 1

  # The attributes which are rendered by the JSON serialization
  # @return [Array<Symbol>]
  def self.json_attributes
    [
      :id,
      :unittitle,
      :has_digital_content,
      :components,
      :title,
      :language,
      :date_created,
      :created,
      :extent,
      :container,
      :heldBy,
      :creator,
      :publisher,
      :memberOf
    ]
  end

  ## Solr Document Field accessor methods

  def components
    # Solr returns a single hash rather than an array when there is only one value
    Array.wrap(fetch(:components, []))
  end

  def level
    values = fetch(:level_ssm, [])
    values.first
  end

  def component_levels
    return unless component?

    fetch(:component_level_isim, [])
  end

  def component_level
    return unless component_levels

    component_levels.first
  end

  def id
    Array.wrap(super).first
  end

  def refs
    fetch("ref_ssm", [])
  end

  def ead
    fetch("ead_ssi", "")
  end

  def http_safe_ead
    ead.tr(".", "-")
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

  def subtitle
    fetch(:subtitle_ssm, [])
  end

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

  def volume
    fetch(:volume_ssm, [])
  end

  def location_note
    fetch(:location_note_ssm, [])
  end

  def location_code
    fetch(:location_code_ssm, [])
  end

  def physical_location_code
    fetch(:physloc_code_ssm, [])
  end
  alias physloc_code physical_location_code

  def physical_description_number
    fetch(:physdesc_number_ssm, [])
  end
  alias physdesc_number physical_description_number

  def has_online_content
    fetch("has_online_content_ssim", [])
  end

  def extents
    fetch("extent_ssm", [])
  end

  def fetch_html_safe(field)
    fetch(field, []).map(&:html_safe)
  end

  def extent
    super || []
  end

  def physical_locations
    values = fetch("physloc_ssm", [])
    return if values.empty?

    values.first.split(", ")
  end

  def last_physical_location
    physical_locations.last
  end

  def scope_contents
    fetch("scopecontent_ssm", [])
  end

  def scope_content
    scope_contents.first
  end

  def arrangements
    fetch("arrangement_ssm", [])
  end

  def arrangement
    arrangements.first
  end

  ## Other Methods
  def root_component?
    component? && component_level == self.class::ROOT_COMPONENT_LEVEL
  end

  def collection?
    return false if level.nil?

    level == self.class::COLLECTION_LEVEL
  end

  def collection_document
    return self if collection?
    @collection_document ||= self.class.find(ead)
  end

  def component?
    key?("component_level_isim")
  end

  def has_digital_content?
    has_online_content.present? && has_online_content.first != "false"
  end

  def component_documents
    components.map { |component_values| self.class.new(component_values) }
  end

  def component_attributes
    component_documents.map(&:attributes)
  end

  def html_presenter_class
    ComponentHtmlPresenter
  end

  # Transform Solr Document into a JSON Object
  # @return [Hash]
  def attributes
    default_attributes = {}
    merged = default_attributes.merge(blacklight_attributes)
    merged = merged.merge(arclight_attributes)
    merged = merged.merge(pulfalight_attributes)
    merged.select { |u, _v| self.class.json_attributes.include?(u) }
  end
  delegate :to_json, to: :attributes

  def aeon_request
    @aeon_request ||= AeonRequest.new(self)
  end

  def storage_notes
    StorageNotes.for(fetch("physloc_ssm", [])).to_a.concat(fetch("location_note_ssm", [])).map(&:html_safe)
  end

  def component_storage_notes
    StorageNotes.for(fetch("collection_physloc_ssm", [])).to_a.concat(fetch("location_note_ssm", [])).map(&:html_safe)
  end

  def language
    fetch("language_ssm", []).map(&:strip)
  end

  def date_created
    fetch("normalized_date_ssm", [])
  end

  def created
    fetch("unitdate_inclusive_ssm", [])
  end

  def extent_and_dimensions
    extent = fetch("extent_ssm", [])
    dimensions = fetch("dimensions_ssm", [])
    extent.zip(dimensions).map do |dimension_extent_arr|
      dimension_extent_arr.compact.join("; ")
    end.map(&:strip)
  end

  def container
    Array.wrap(containers.join(", "))
  end

  def held_by
    return location_code if location_code.present? && collection?
    fetch("container_location_codes_ssim", []).map do |code|
      if Pulfalight::LocationCode.registered?(code)
        Pulfalight::LocationCode.map(code)
      else
        code
      end
    end
  end

  def publisher
    fetch("collection_creator_ssm", [])
  end

  def member_of
    return if collection?
    [
      {
        title: collection_name,
        identifier: collection_unitid
      }
    ]
  end

  def restricted?
    fetch("access_ssi", nil) == "restricted"
  end

  def some_restricted?
    fetch("access_ssi", nil) == "some-restricted"
  end

  def render_panopto?
    panopto_digital_object.present?
  end

  def panopto_digital_object
    @panopto_digital_object ||=
      begin
        found_dao = direct_digital_objects.find do |dao|
          dao.href.include?("princeton.hosted.panopto.com")
        end
        return if found_dao.nil?
        # Decorate functionality for getting ID.
        PanoptoDao.new(found_dao)
      end
  end

  def figgy_digital_objects
    @figgy_digital_objects ||=
      begin
        direct_digital_objects.select do |dao|
          dao.href.to_s.include?(Pulfalight.config["figgy_url"])
        end
      end
  end

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
      scopecontent: scopecontent,
      language: language,
      date_created: date_created,
      created: created,
      extent: extent_and_dimensions,
      container: container,
      heldBy: held_by,
      publisher: publisher,
      memberOf: member_of
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
