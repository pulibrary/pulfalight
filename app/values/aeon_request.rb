# frozen_string_literal: true
class AeonRequest
  attr_reader :solr_document
  def initialize(solr_document)
    @solr_document = solr_document
  end

  def requestable?
    solr_document["components"].blank? && container_locations.present?
  end

  def attributes
    {
      callnumber: solr_document.id,
      title: solr_document.title&.first,
      containers: solr_document["physloc_ssm"]&.first
    }
  end

  def form_attributes
    {
      AeonForm: "EADRequest",
      RequestType: "Loan",
      DocumentType: "Manuscript",
      Site: solr_document["physloc_code_ssm"]&.first,
      Location: container_locations,
      ItemTitle: solr_document.title&.first,
      Request: request_id,
      "ItemSubTitle_#{request_id}": subtitle,
      "ItemTitle_#{request_id}": title,
      "ItemAuthor_#{request_id}": solr_document.creator,
      "ItemDate_#{request_id}": date,
      "ReferenceNumber_#{request_id}": solr_document.id,
      "CallNumber_#{request_id}": solr_document.eadid,
      "ItemNumber_#{request_id}": barcode,
      "ItemVolume_#{request_id}": box,
      "ItemInfo1_#{request_id}": access_restrictions,
      "ItemInfo2_#{request_id}": solr_document.extent,
      "ItemInfo3_#{request_id}": folder,
      "ItemInfo4_#{request_id}": container_profile,
      "ItemInfo5_#{request_id}": url,
      "Location_#{request_id}": container_locations,
      "GroupingField_#{request_id}": grouping_identifier
    }.merge(grouping_options)
  end

  # Group all box components in the same EAD together.
  def grouping_identifier
    "#{ead_id}-#{box}"
  end

  def ead_id
    Array.wrap(solr_document.fetch("ead_ssi", [])).first
  end

  def container_locations
    solr_document.fetch("container_location_codes_ssim", []).map { |code| translate_location_code(code) }.join(", ")
  end

  def container_profile
    solr_document.fetch("container_information_ssm", []).map do |container|
      container = JSON.parse(container)
      container["profile"]
    end.join(", ")
  end

  def translate_location_code(code)
    return "ReCAP" if code.downcase.start_with?("rcp")
    code
  end

  def url
    Rails.application.routes.url_helpers.solr_document_url(id: solr_document.id)
  end

  def folder
    return if non_box_containers.blank?
    non_box_containers.join(", ")
  end

  def non_box_containers
    solr_document.containers.reject do |container|
      container.to_s.downcase.include?("box")
    end
  end

  def access_restrictions
    solr_document["accessrestrict_ssm"]&.first
  end

  def box
    solr_document["containers_ssim"]&.first&.upcase_first
  end

  def barcode
    solr_document["barcodes_ssim"]&.first
  end

  def title
    solr_document["parent_unnormalized_unittitles_ssm"]&.first || solr_document.title&.last
  end

  def date
    solr_document["unitdate_inclusive_ssm"]&.first
  end

  def subtitle
    [solr_document["parent_unnormalized_unittitles_ssm"]&.last, solr_document.title&.last].compact.join(" / ")
  end

  def request_id
    @request_id ||= SecureRandom.hex(14).to_i(16).to_s
  end

  private

  def grouping_options
    {
      GroupingIdentifier: "GroupingField",
      GroupingOption_ReferenceNumber: "Concatenate",
      GroupingOption_ItemNumber: "Concatenate",
      GroupingOption_ItemDate: "FirstValue",
      GroupingOption_CallNumber: "FirstValue",
      GroupingOption_ItemVolume: "FirstValue",
      GroupingOption_ItemInfo1: "FirstValue",
      GroupingOption_ItemInfo3: "Concatenate",
      GroupingOption_Location: "FirstValue",
      SubmitButton: "Submit Request"
    }
  end
end
