# frozen_string_literal: true
module Pulfalight::Document::XMLExport
  def self.extended(document)
    document.will_export_as(:xml)
  end

  def export_as_xml
    client.get_xml(eadid: eadid)
  end

  def client
    Aspace::Client.new
  end
end
