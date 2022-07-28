# frozen_string_literal: true
module Pulfalight::Document::XMLExport
  def self.extended(document)
    document.will_export_as(:xml)
  end

  def export_as_xml
    content = client.get_xml(eadid: collection_unitid || unitid)
    document = Nokogiri::XML.parse(content)
    document = strip_containers(document) unless export_xml_containers?
    document = add_pul_to_repository(document)
    return document if collection?
    document = document.remove_namespaces!
    document.xpath("//*[@id='#{id}']")[0].to_xml
  end

  def strip_containers(document)
    document.xpath("//xmlns:container").each(&:remove)
    document
  end

  def add_pul_to_repository(document)
    document.xpath("//xmlns:repository/xmlns:corpname").each do |node|
      node.inner_html = "Princeton University Library: #{node.text.strip}"
    end
    document
  end

  def export_xml_containers?
    @suppress_xml_containers != true
  end

  def suppress_xml_containers!
    @suppress_xml_containers = true
  end

  def client
    Aspace::Client.new
  end
end
