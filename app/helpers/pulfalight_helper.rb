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

  private

  def repository_thumbnail_path
    image_path("default_repository_thumbnail.jpg")
  end
end
