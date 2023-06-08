# frozen_string_literal: true

module Pulfalight
  class DeliveryNote
    attr_reader :location_code
    def initialize(location_code)
      @location_code = location_code
    end

    def brief_note
      return unless delivery_warning_locations.include?(location_code)
      "This item is stored offsite. Please allow up to 3 business days for delivery."
    end

    def delivery_warning_locations
      ["rcpph", "rcpxc", "rcpxg", "rcpxm", "rcpxr"]
    end
  end
end
