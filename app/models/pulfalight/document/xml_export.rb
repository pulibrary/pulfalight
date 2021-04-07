# frozen_string_literal: true
module Pulfalight::Document::XMLExport
  def self.extended(document)
    document.will_export_as(:xml)
  end

  def export_as_xml
    content = client.get_xml(eadid: eadid)
    return content if collection?
    document = Nokogiri::XML.parse(content)
    document.xpath("//*[@id='#{id}']")[0].to_xml
  end

  def client
    Aspace::Client.new
  end
end
