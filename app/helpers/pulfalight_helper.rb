# frozen_string_literal: true
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

  def collection_link
    collection_id = document.fetch("ead_ssi", nil)
    return "/catalog/#{collection_id}" if collection_id
  end

  private

  def repository_thumbnail_path
    image_path("default_repository_thumbnail.jpg")
  end
end
