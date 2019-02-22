
# frozen_string_literal: true
module Pulfa
  class NormalizedDate < Arclight::NormalizedDate
    # @param [String | Array<String>] `inclusive` from the `unitdate`
    # @param [String] `bulk` from the `unitdate`
    # @param [String] `other` from the `unitdate` when type is not specified
    def initialize(inclusive, bulk = nil, other = nil)
      if inclusive.is_a? Array # of YYYY-YYYY for ranges
        @inclusive = YearRange.new(inclusive.include?('/') ? inclusive : inclusive.map { |v| v.tr('-', '/') }).to_s
      elsif inclusive.present?
        @inclusive = inclusive.strip
      end
      @bulk = bulk.strip if bulk.present?
      @other = other.strip if other.present?
    end
  end
end
