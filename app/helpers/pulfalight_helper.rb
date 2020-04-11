# frozen_string_literal: true
module PulfalightHelper
  # Retrieves the current year
  # @return [Integer]
  def current_year
    DateTime.current.year
  end

  def repository_config_present?(_, document)
    document.repository_config.present?
  end
  alias request_config_present? repository_config_present?

  # Is this needed?
  def document
    @document
  end

  def aeon_external_request(document)
    document.build_external_request(presenter: show_presenter(document))
  end

  # @override
  def normalize_id(id)
    Arclight::NormalizedId.new(id).to_s
  rescue Arclight::Exceptions::IDNotFound
    SecureRandom.hex(14)
  end

  ##
  # @override
  # @param [SolrDocument]
  def document_parents(document)
    parents = Pulfalight::Parents.from_solr_document(document)
    parents.as_parents
  end

  ##
  # @override
  # @param [SolrDocument]
  def parents_to_links(document)
    breadcrumb_links = []

    breadcrumb_links << build_repository_link(document)

    breadcrumb_links << document_parents(document).map do |parent|
      link_to parent.label, solr_document_path(parent.global_id)
    end

    safe_join(breadcrumb_links, aria_hidden_breadcrumb_separator)
  end

  def overridden_document_parents(document)
    Pulfalight::Parents.from_solr_document(document).as_parents
  end

  def overridden_parents_to_links(document)
    breadcrumb_links = []

    breadcrumb_links << build_repository_link(document)

    breadcrumb_links << overridden_document_parents(document).map do |parent|
      link_to parent.label, solr_document_path(parent.global_id)
    end

    safe_join(breadcrumb_links, aria_hidden_breadcrumb_separator)
  end
end
