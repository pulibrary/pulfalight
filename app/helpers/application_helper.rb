# frozen_string_literal: true
module ApplicationHelper
  # Retrieves the current year
  # @return [Integer]
  def current_year
    DateTime.current.year
  end

  def aeon_external_request_class
    Plantain::Requests::AeonExternalRequest
  end
end
