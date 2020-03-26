# frozen_string_literal: true

module Pulfalight
  # Class for normalizing dates from year strings extracted from the EAD
  class NormalizedDate < Arclight::NormalizedDate
    # Constructor
    # @param inclusive [Array<String>, String]
    # @param bulk [Array<String>, String]
    # @param other [Array<String>, String]
    def initialize(inclusive, bulk = nil, other = nil)
      if inclusive.is_a? Array # of YYYY-YYYY for ranges
        @inclusive = YearRange.new(inclusive.include?("/") ? inclusive : inclusive.map { |v| v.tr("-", "/") }).to_s
      elsif inclusive.present?
        @inclusive = inclusive.strip
      end
      bulk_date = Array.wrap(bulk).first
      @bulk = bulk_date.strip if bulk_date.present?
      other_date = Array.wrap(other).first
      @other = other_date.strip if other_date.present?
    end
  end
end
