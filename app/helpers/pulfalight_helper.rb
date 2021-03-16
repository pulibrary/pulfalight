# frozen_string_literal: true
require "arclight_helper"
module PulfalightHelper
  # Retrieves the current year
  # @return [Integer]
  def current_year
    DateTime.current.year
  end

  def document
    @document
  end
  alias collection_document document
  alias component_document document

  def html_presenter
    document.presenter
  end

  def component_notes_formatter(*_args)
    html_presenter.collection_notes
  end

  # @return [Class]
  def aeon_external_request_class
    Pulfalight::Requests::AeonExternalRequest
  end

  # This needs to parse the config/aeon.yml file
  def available_request_types
    [:aeon_external_request_endpoint]
  end

  def repository_thumbnail
    img_src = if document&.repository_config&.thumbnail_url
                document.repository_config.thumbnail_url
              else
                repository_thumbnail_path
              end

    image_tag(img_src, alt: "", class: "img-fluid float-left")
  end

  def render_simple_link
    SimpleLinkRenderer.render(document)
  end

  def render_universal_viewer
    UniversalViewerRenderer.render(document)
  end

  def generic_should_render_field?(config_field, document, field)
    super && show_presenter(document).with_field_group(config_field).field_value(field).present?
  end

  def display_simple_link?
    dao = document.direct_digital_objects
    return if dao.blank?
    uri = URI.parse(dao.first&.href)
    uri.is_a?(URI::HTTP)
  end

  ##
  # Class used for specifying main layout container classes. Can be
  # overwritten to return 'container-fluid' for Bootstrap full-width layout
  # @return [String]
  def container_classes
    "container-fluid"
  end

  def ark_link(_context)
    ark = document.fetch("ark_tsim", []).first
    return if ark.blank?
    link_to ark, ark
  end

  # Render an html <title> appropriate string for a set of search parameters
  # @param [ActionController::Parameters] params2
  # @return [String]
  def render_search_to_page_header(params)
    constraints = []
    constraints += (params.dig("f", "collection_sim") || [])
    constraints.join(" / ")
  end

  def hr_separator(args)
    # Indent
    # safe_join(args[:value].map { |val| tag.span(val, class: "metadata-note") })
    # Horizontal Rule
    # safe_join(args[:value], "<hr />".html_safe)
    # Bullets
    tag.ul(safe_join(args[:value].map { |val| tag.li(val) }))
  end

  private

  def repository_thumbnail_path
    image_path("default_repository_thumbnail.jpg")
  end
end
