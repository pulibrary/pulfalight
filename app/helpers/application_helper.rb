# frozen_string_literal: true
module ApplicationHelper
  # Retrieves the current year
  # @return [Integer]
  def current_year
    DateTime.current.year
  end
end
