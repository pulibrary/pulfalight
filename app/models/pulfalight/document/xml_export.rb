# frozen_string_literal: true
module Pulfalight::Document::XMLExport
  def self.extended(document)
    document.will_export_as(:xml)
  end

  def export_as_xml
    content = client.get_xml(eadid: collection_unitid || unitid)
    content = strip_containers(content) unless export_xml_containers?
    content = add_pul_to_repository(content)
    return content if collection?
    document = Nokogiri::XML.parse(content).remove_namespaces!
    document.xpath("//*[@id='#{id}']")[0].to_xml
  end

  def strip_containers(content)
    document = Nokogiri::XML.parse(content)
    document.xpath("//xmlns:container").each(&:remove)
    document.to_s
  end

  def add_pul_to_repository(content)
    document = Nokogiri::XML.parse(content)
    document.xpath("//xmlns:repository/xmlns:corpname").each do |node|
      node.inner_html = "Princeton University Library: #{node.text.strip}"
    end
    document.to_s
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
