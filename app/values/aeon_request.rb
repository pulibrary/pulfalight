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
      Site: site,
      Location: container_locations,
      ItemTitle: title
    }.merge(grouping_options).merge(all_request_attributes)
  end

  def all_request_attributes
    return request_attributes({}) if box.blank?
    all_attributes = requesting_containers.map do |local_box|
      request_attributes(local_box)
    end
    return request_attributes({}) if all_attributes.blank?
    # Combine request attributes, but merge duplicate keys - necessary for
    # Request to end up with an array of values.
    all_attributes.inject do |combined, request_attributes|
      combined.merge(request_attributes) do |_key, oldval, newval|
        Array.wrap(oldval) + [newval]
      end
    end
  end

  def requesting_containers
    return boxes if boxes.present?
    non_boxes
  end

  # Create one request per box.
  def request_attributes(box)
    {
      Request: request_id(box),
      "Location_#{request_id(box)}": translate_location_code(box["location_code"]),
      "GroupingField_#{request_id(box)}": grouping_identifier(box),
      "ItemSubTitle_#{request_id(box)}": subtitle,
      "ItemTitle_#{request_id(box)}": title,
      "ItemAuthor_#{request_id(box)}": solr_document.creator,
      "ItemDate_#{request_id(box)}": date,
      "ReferenceNumber_#{request_id(box)}": solr_document.id,
      "CallNumber_#{request_id(box)}": solr_document.eadid,
      "ItemNumber_#{request_id(box)}": box["barcode"],
      "ItemVolume_#{request_id(box)}": box["label"]&.upcase_first,
      "ItemInfo1_#{request_id(box)}": access_restrictions,
      "ItemInfo2_#{request_id(box)}": solr_document.extent,
      "ItemInfo3_#{request_id(box)}": folder,
      "ItemInfo4_#{request_id(box)}": box_locator(box),
      "ItemInfo5_#{request_id(box)}": url
    }
  end

  def box_locator(box)
    [box["profile"], box["note"]].select(&:present?).join(" ")
  end

  def site
    solr_document["physloc_code_ssm"]&.first || "RBSC"
  end

  # Group all box components in the same EAD together.
  def grouping_identifier(box)
    "#{ead_id}-#{box['label'].to_s.tr(' ', '-')}"
  end

  def ead_id
    Array.wrap(solr_document.fetch("ead_ssi", [])).first
  end

  def container_locations
    solr_document.fetch("container_location_codes_ssim", []).map { |code| translate_location_code(code) }.join(", ")
  end

  def container_information
    @container_information ||=
      begin
        solr_document.fetch("container_information_ssm", []).map do |container|
          JSON.parse(container)
        end
      end
  end

  def translate_location_code(code)
    return "ReCAP" if code.to_s.downcase.start_with?("rcp")
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
    solr_document["accessrestrict_ssm"]&.first&.truncate(75)
  end

  def box
    solr_document["containers_ssim"]&.first&.upcase_first
  end

  def boxes
    container_information.select do |container|
      container["label"].to_s.downcase.include?("box")
    end
  end

  def non_boxes
    container_information.select do |container|
      !container["label"].to_s.downcase.include?("box")
    end
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

  def request_id(box)
    "#{static_request_id}#{box['label'].to_s.tr(' ', '-')}"
  end

  def static_request_id
    @static_request_id ||= SecureRandom.hex(14).to_i(16).to_s
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
