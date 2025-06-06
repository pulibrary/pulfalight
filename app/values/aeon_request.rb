# frozen_string_literal: true
class AeonRequest
  # These parameters have to be sent with no duplication on every Aeon API
  # request.
  def self.global_form_params
    {
      SystemID: "Pulfa",
      AeonForm: "EADRequest",
      UserReview: "No",
      WebRequestForm: "EADRequest",
      RequestType: "Loan",
      DocumentType: "Manuscript",
      Location: "sc",
      GroupingIdentifier: "GroupingField",
      GroupingOption_ReferenceNumber: "Concatenate",
      GroupingOption_ItemTitle: "FirstValue",
      GroupingOption_ItemNumber: "FirstValue",
      GroupingOption_ItemDate: "FirstValue",
      GroupingOption_CallNumber: "FirstValue",
      GroupingOption_ItemVolume: "FirstValue",
      GroupingOption_ItemInfo1: "FirstValue",
      GroupingOption_ItemInfo3: "Concatenate",
      GroupingOption_ItemInfo4: "FirstValue",
      GroupingOption_Location: "FirstValue",
      GroupingOption_Site: "FirstValue",
      SubmitButton: "Submit Request"
    }
  end

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

  def location_attributes
    note = Pulfalight::DeliveryNote.new(solr_document["container_location_codes_ssim"]&.first).brief_note
    { notes: note, label: site_info[site][:label], url: site_info[site][:url] }
  end

  def site_info
    {
      "FIRE" => {
        label: "Firestone Library",
        url: "https://library.princeton.edu/special-collections/visit-us"
      },
      "MUDD" => {
        label: "Mudd Manuscript Library",
        url: "https://library.princeton.edu/special-collections/visit-us"
      },
      "Engineering Library" => {
        label: "Engineering Library",
        url: "https://library.princeton.edu/engineering"
      }
    }
  end

  def form_attributes
    return request_attributes({}) if box.blank?
    all_attributes = top_containers.map do |local_box|
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

  # Create one request per box.
  def request_attributes(box)
    {
      Request: request_id(box),
      "Site_#{request_id(box)}": site,
      "Location_#{request_id(box)}": translate_location_code(box["location_code"]),
      "GroupingField_#{request_id(box)}": grouping_identifier(box),
      "ItemSubTitle_#{request_id(box)}": subtitle,
      "ItemTitle_#{request_id(box)}": title,
      "ItemAuthor_#{request_id(box)}": solr_document.creator,
      "ItemDate_#{request_id(box)}": date,
      "ReferenceNumber_#{request_id(box)}": solr_document.id,
      "CallNumber_#{request_id(box)}": solr_document.eadid,
      "ItemNumber_#{request_id(box)}": box["barcode"],
      "ItemVolume_#{request_id(box)}": item_volume(box),
      "ItemInfo1_#{request_id(box)}": CGI.escapeHTML(access_restrictions),
      "ItemInfo2_#{request_id(box)}": solr_document.extent,
      "ItemInfo3_#{request_id(box)}": folder(box),
      "ItemInfo4_#{request_id(box)}": box_locator(box),
      "ItemInfo5_#{request_id(box)}": url
    }
  end

  def item_volume(box)
    [box["label"]&.upcase_first, item_number_label].compact.join(" ")
  end

  def item_number_label
    return if solr_document.unitid.blank?
    "Item Number: #{solr_document.unitid}"
  end

  def box_locator(box)
    [box["profile"], box["note"]].select(&:present?).join(" ")
  end

  def site
    physloc = solr_document["physloc_code_ssm"]&.first || "FIRE"
    return "FIRE" if physloc == "RBSC"
    physloc
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
      solr_document.fetch("container_information_ssm", []).map do |container|
        JSON.parse(container)
      end
  end

  def translate_location_code(code)
    return "ReCAP" if code.to_s.downcase.start_with?("rcp")
    code
  end

  def url
    Rails.application.routes.url_helpers.solr_document_url(id: solr_document.id)
  end

  def folder(box)
    folders = container_information.select do |container|
      container["parent"] == box["id"] && container["type"] == "folder"
    end
    return if folders.blank? && non_box_containers.blank?
    return non_box_containers.join(", ") if folders.blank?
    folders = folders.map { |folder| folder["label"].capitalize }
    folders.join(", ")
  end

  def non_box_containers
    solr_document.containers.reject do |container|
      container.to_s.downcase.include?("box")
    end
  end

  def access_restrictions
    solr_document["accessrestrict_ssm"]&.first&.truncate(75).to_s
  end

  def box
    solr_document["containers_ssim"]&.first&.upcase_first
  end

  # Top containers are boxes and oversize folders.
  def top_containers
    container_information.select do |container|
      container["parent"].blank?
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
end
