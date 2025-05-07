# frozen_string_literal: true
module Pulfalight::Document::XmlExport
  def self.extended(document)
    document.will_export_as(:xml)
  end

  def export_as_xml
    document = Nokogiri::XML.parse(xml_content)
    document = strip_containers(document) unless export_xml_containers?
    document = add_pul_to_repository(document)
    return document if collection?
    document = document.remove_namespaces!
    component = document.xpath("//*[@id='#{refs.first}']")[0]
    if component
      component.to_xml
    else
      Rails.logger.warn("Error generating xml: #{id}")
      raise ActionController::RoutingError, "xml export error"
    end
  end

  def xml_content
    client.get_xml(eadid: collection_unitid || unitid)
  rescue => e
    Rails.logger.warn("#{e.class}: #{e}")
    raise e.class, "xml export error"
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
