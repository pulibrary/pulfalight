# frozen_string_literal: true

module Pulfalight
  # Class for normalizing dates from year strings extracted from the EAD
  class NormalizedDate < Arclight::NormalizedDate
    # Constructor
    # @param inclusive [Array<String>, String]
    # @param bulk [Array<String>, String]
    # @param other [Array<String>, String]
    def initialize(inclusive, bulk = nil, other = nil)
      @inclusive = process_inclusive(inclusive)
      bulk_date = Array.wrap(bulk).first
      @bulk = bulk_date.strip if bulk_date.present?
      other_date = Array.wrap(other).first
      @other = other_date.strip if other_date.present?
    end

    # Process inclusive date value(s)
    # @param value [Array<String>, String]
    # @return [String]
    def process_inclusive(value)
      if value.is_a?(Array) && valid_ranges?(value)
        YearRange.new(value.include?("/") ? value : value.map { |v| v.tr("-", "/") }).to_s
      elsif value.is_a? Array
        value.each { |d| d.strip.tr("/", "-") }.join(", ")
      elsif value.present?
        value.strip
      end
    end

    # Tests if all dates in an array are a valid date range
    # Valid: YYYY-YYYY
    # Valid: YYYY/YYYY
    # Not-valid: circa YYYY/YYYY
    # @param dates [Array<String>]
    # @return [Boolean]
    def valid_ranges?(dates)
      dates.each do |date|
        return false unless /^\d{4}.\d{4}$/.match?(date.strip)
      end

      true
    end
  end
end
