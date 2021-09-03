# frozen_string_literal: true

module Pulfalight
  # Class for normalizing box locations to assemble the Magic Physloc Note
  # It accepts a hash that looks like this:
  # {
  #   "hsvm" => ["1", "323", "2", "3", "4", "5", "6"],
  #   "mss" => ["12", "20", "21", "30", "31"],
  #   "rcpxm" => ["266", "114", "105", "106"]
  # }
  # ... and turns it into a string that looks like this:
  # "This collection is stored in multiple locations:
  # Firestone Library Vault: Boxes 1-6; 323
  #
  class NormalizedBoxLocations
    # @param [Hash] box_locations
    def initialize(box_locations)
      @normalized_locations = {}

      box_locations.keys.each do |location|
        @normalized_locations[translate_location(location)] = calculate_box_ranges(box_locations[location])
      end
    end

    def translate_location(location)
      "#{Pulfalight::LocationCode.resolve(location)} (#{location})"
    rescue Pulfalight::UnrecognizedLocationError
      location
    end

    def locations
      @normalized_locations.keys
    end

    # Given a location code, return the relevent box ranges
    def ranges_for(location_code)
      key = @normalized_locations.keys.find { |a| a =~ /#{location_code}/ }
      @normalized_locations[key]
    end

    ##
    # Given an array of box ids:
    # 1. Remove any that are not integers
    # 2. Sort and group the integers into ranges
    # 3. Consolidate any ranges that represent a single box
    # 4. Re-add the non-integer box ids
    # @param [<String>] box_numbers
    # @return [<String>]
    def calculate_box_ranges(box_numbers)
      non_numeric_box_ids = box_numbers.reject { |a| a.to_i.to_s == a }
      sorted = box_numbers.uniq.map(&:to_i).sort
      ranges = []
      first_number = nil

      (1..sorted.max).each do |index|
        first_number = index if sorted.include?(index) && first_number.nil?

        if !sorted.include?(index) && !first_number.nil?
          range = "#{first_number}-#{index - 1}"
          ranges << range
          first_number = nil
        end

        # In case the last number in the series is a singleton
        if sorted.include?(index) && index == sorted.max
          range = "#{first_number}-#{index}"
          ranges << range
        end
      end
      ranges.map { |a| consolidate_single_box_ranges(a) } | non_numeric_box_ids
    end

    def to_s
      normalize
    end

    private

    # Consolidate any box ranges that are only a single box
    def consolidate_single_box_ranges(range)
      box_numbers = range.split("-")
      first = box_numbers.first
      last = box_numbers.last
      return first if first == last
      range
    end

    def box_or_boxes(location)
      boxes = @normalized_locations[location]
      return "Box" if boxes.size == 1 && boxes.first != ~ /-/
      "Boxes"
    end

    # Generate a human readable summary of the box locations
    # @return [String]
    def normalize
      message_strings = []
      message_strings << "This is stored in multiple locations. " if locations.size > 1
      @normalized_locations.keys.each do |location|
        m = "#{location}: #{box_or_boxes(location)} #{@normalized_locations[location].join('; ')}"
        message_strings << m
      end
      message_strings.join(" ")
    end
  end
end
