
# frozen_string_literal: true
module Pulfa
  class YearRange < Arclight::YearRange
    # Parse a range of dates extracted from a document into a range of years
    # @param dates [Array<String>]
    # @return [Array<Integer>]
    def parse_range(dates)
      return if dates.blank?
      year_u, year_v = dates.split('/').map { |date| to_year_from_iso8601(date) }
      return [year_u] if year_v.blank?
      raise ArgumentError, "Range is too large: #{dates}" if (year_v - year_u) > 1000 || (year_u - year_v) > 1000
      return (year_v..year_u).to_a unless year_u <= year_v
      (year_u..year_v).to_a
    end
  end
end
