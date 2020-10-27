# frozen_string_literal: true
class AeonRequest
  attr_reader :solr_document
  def initialize(solr_document)
    @solr_document = solr_document
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
      Location: solr_document.fetch("container_location_codes_ssim", []).join(", "),
      ItemTitle: solr_document.title&.first,
      Request: request_id,
      "ItemSubTitle_#{request_id}": subtitle
    }.merge(grouping_options)
  end

  def subtitle
    [solr_document["parent_unnormalized_unittitles_ssm"]&.last, solr_document.title&.last].compact.join(" / ")
  end

  def request_id
    @request_id ||= SecureRandom.hex(14).to_i(16)
  end

  private

  def grouping_options
    {
      GroupingIdentifier: "ItemVolume",
      GroupingOption_ReferenceNumber: "Concatenate",
      GroupingOption_ItemNumber: "Concatenate",
      GroupingOption_ItemDate: "FirstValue",
      GroupingOption_CallNumber: "FirstValue",
      GroupingOption_ItemVolume: "FirstValue",
      GroupingOption_ItemInfo1: "FirstValue",
      GroupingOption_Location: "FirstValue"
    }
  end
end
