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

  # This shouldn't need to be overridden
  def repository_config
    return unless repository

    @repository_config ||= Arclight::Repository.find_by(name: repository)
  end

  def extent
    super.first
  end

  def self.aeon_external_request_class
    Pulfalight::Requests::AeonExternalRequest
  end

  def self.default_available_request_types
    [:aeon_external_request_endpoint]
  end

  def build_external_request(presenter:)
    self.class.aeon_external_request_class.new(self, presenter)
  end

  def available_request_types
    return self.class.default_available_request_types unless repository_config

    repository_config.available_request_types
  end

  def level
    values = fetch(:level_ssm, [])
    values.first
  end

  def collection?
    return false if level.nil?

    level == "collection"
  end

  def collection_solr_document
    @collection_solr_document ||= begin
                                    parent_id = fetch(:_root_, "")
                                    parent_id = fetch(:ead_ssi, "") if parent_id.empty?
                                    return if parent_id.empty?

                                    solr_response = Blacklight.default_index.find(parent_id, fl: "*,[child]")
                                    response = solr_response["response"]
                                    docs = response["docs"]
                                    docs.last
                                  end
  end

  def collection
    @collection ||= begin
                      return self if collection?
                      return unless collection_solr_document

                      self.class.new(collection_solr_document)
                    end
  end

  def title
    values = fetch(:title_ssm, [])
    values.first
  end

  def subtitle
    values = fetch(:subtitle_ssm, [])
    values.first
  end

  def acqinfo
    values = fetch(:acqinfo_ssm, [])
    values.first
  end

  def volume
    return unless physical_holding.box_number

    "Box#{physical_holding.box_number}"
  end

  def eadid
    values = fetch(:eadid_ssm, [])
    values.first
  end

  def build_containers
    values = fetch(:containers, [])
    values.map { |_v| self.class.new(value) }
  end

  def containers
    @containers ||= build_containers
  end

  def container_titles
    @container_titles ||= containers.map(&:title)
  end

  # These are used to bind data to the Vue component for requests
  def container_attributes
    containers.map do |container|
      {
        type: container.type,
        value: container.number
      }
    end
  end

  def subcontainers
    @subcontainers || containers.map(&:containers).flatten
  end

  # These are used to bind data to the Vue component for requests
  def subcontainer_attributes
    subcontainers.map do |container|
      {
        type: container.type,
        value: container.number
      }
    end
  end

  def self.physical_holding_class
    PhysicalHolding
  end

  def build_physical_holding
    values = fetch(:physical_holdings, {})
    return collection.physical_holding if values.empty? && collection&.physical_holding
    return if values.empty?

    self.class.physical_holding_class.new(values)
  end

  def physical_holding
    @physical_holding ||= build_physical_holding
  end
  # delegate :barcode, :unitid, :physloc, :container_values, :callnumber, to: :physical_holding

  def barcode
    physical_holding&.barcode
  end

  def unitid_attributes
    physical_holding&.unitid_attributes
  end

  def physloc_notes
    physical_holding&.physloc_notes
  end

  def physloc_code
    physical_holding&.physloc_code
  end

  def physloc_attributes
    physical_holding&.physloc_attributes
  end

  def callnumber
    physical_holding&.callnumber
  end

  class PhysicalHolding
    include Blacklight::Solr::Document
    include Arclight::SolrDocument

    def barcode
      values = fetch(:barcode_ssm, [])
      values.first
    end

    def box_number
      fetch(:box_number_ssi, nil)
    end

    def unitid
      values = fetch(:unitid_ssm, [])
      values.first
    end
    alias callnumber unitid

    # This is based off of the example
    def unitid_attributes
      {
        type: "barcode",
        value: unitid
      }
    end

    def physloc_notes
      fetch(:physical_location_notes_ssm, [])
    end

    def physloc_code
      values = fetch(:physical_location_code_ssm, [])
      values.first
    end

    def physloc_attributes
      {
        type: "code",
        value: physloc_code
      }
    end
  end
end
