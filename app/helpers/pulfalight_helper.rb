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

  def collection_notes_formatter(*_args)
    html_presenter.notes
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
end
