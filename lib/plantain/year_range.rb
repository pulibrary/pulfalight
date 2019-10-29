# frozen_string_literal: true

module Plantain
  # Class for modeling ranges in years parsed from encoded dates in EAD Documents
  class YearRange < Arclight::YearRange
    # Parses an array of dates from a string extracted from an EAD Document
    # @param dates [String]
    # @return [Array<Integer>]
    def parse_range(dates)
      return if dates.blank?
      year_u, year_v = dates.split("/").map { |date| to_year_from_iso8601(date) }
      return [year_u] if year_v.blank?
      return (year_v..year_u).to_a unless year_u <= year_v
      (year_u..year_v).to_a
    end
  end
end
