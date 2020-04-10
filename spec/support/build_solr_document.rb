# frozen_string_literal: true

module BuildSolrDocument
  def build_solr_document(fixture_file_path, solr_response)
    fixture_json = File.read(fixture_file_path)
    json = JSON.parse(fixture_json)
    SolrDocument.new(json, solr_response)
  end
end
