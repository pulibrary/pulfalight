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
      @bulk = process_bulk(bulk)
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

    # Process bulk dates value(s).
    # Assume we'll only ever have one "bulk" date.
    # @param value [Array<String>, String]
    # @return [String]
    def process_bulk(value)
      return if value.nil?

      unprocessed_date = value.first
      if valid_ranges?(Array.wrap(unprocessed_date))
        YearRange.new(value.include?("/") ? value : value.map { |v| v.tr("-", "/") }).to_s
      else
        unprocessed_date.strip.tr("/", "-")
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

    # Override from Arclight::NormalizedDate
    # @see http://www2.archivists.org/standards/DACS/part_I/chapter_2/4_date for rules
    def normalize
      if inclusive.present?
        result = inclusive.to_s
        result << " (mostly #{bulk})" if bulk.present?
      elsif other.present?
        result = other.to_s
      else
        result = nil
      end

      result&.strip
    end
  end
end
