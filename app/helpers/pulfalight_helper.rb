# frozen_string_literal: true

module PulfalightHelper
  # Retrieves the current year
  # @return [Integer]
  def current_year
    DateTime.current.year
  end

  def aeon_external_request_class
    Pulfalight::Requests::AeonExternalRequest
  end

  # This needs to parse the config/aeon.yml file
  def available_request_types
    [:aeon_external_request_endpoint]
  end
end
