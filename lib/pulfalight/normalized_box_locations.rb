# frozen_string_literal: true

module Pulfalight
  # Class for normalizing container locations to assemble the Magic Physloc Note
  # It accepts a hash that looks like this:
  # {
  #   "hsvm" => {"box" => ["1", "323", "2", "3", "4", "5", "6"], "volume" => ["42", "43", "44", "45"]},
  #   "mss" => {"box" => ["12", "20", "21", "30", "31"]},
  #   "rcpxm" => {"box" => ["266", "114", "105", "106"]}
  # }
  # ... and turns it into a string that looks like this:
  # Firestone Library Vault: Boxes 1-6; 323
  #
  class NormalizedBoxLocations
    # @param [Hash] container_locations
    def initialize(container_locations)
      @normalized_locations = {}

      container_locations.each do |location, types_hash|
        types_hash.each do |type, indicators_array|
          key = translate_location(location)
          @normalized_locations[key] =
            @normalized_locations.fetch(key, {}).merge({ type => calculate_container_ranges(indicators_array) })
        end
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

    # Given a location code, return the relevant container ranges
    def ranges_for(location_code)
      key = @normalized_locations.keys.find { |a| a =~ /#{location_code}/ }
      @normalized_locations[key]
    end

    ##
    # Given an array of container numbers:
    # 1. Remove any that are not integers
    # 2. Sort and group the integers into ranges
    # 3. Consolidate any ranges
    # 4. Re-add the non-integer container numbers
    # Ranges for abid'd (e.g. "P-094623") containers are computed in summary_storage_note_presenter.rb
    # @param [<String>] numbers
    # @return [<String>]
    def calculate_container_ranges(numbers)
      non_numeric_ids = numbers.reject { |a| a.to_i.to_s == a }
      sorted = numbers.uniq.map(&:to_i).sort
      ranges = []
      first_number = nil

      (1..sorted.max).each do |index|
        first_number = index if sorted.include?(index) && first_number.nil?

        if sorted.exclude?(index) && !first_number.nil?
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
      ranges.map { |a| consolidate_single_container_ranges(a) } | non_numeric_ids
    end

    # Generate a human readable summary of the container locations
    def to_s
      normalize.join(" ")
    end

    def to_h
      normalize
    end

    private

    # Consolidate any ranges that are only a single container
    def consolidate_single_container_ranges(range)
      numbers = range.split("-")
      first = numbers.first
      last = numbers.last
      return first if first == last
      range
    end

    def container_label(type, ranges)
      return type.capitalize if ranges.size == 1 && ranges.first !~ /-/
      type.pluralize.capitalize
    end

    # @return [Array<String>]
    def normalize
      @normalized_locations.each do |location, types_hash|
        @normalized_locations[location] = transform_types_hash(types_hash)
      end
      @normalized_locations
    end

    def transform_types_hash(hash)
      # a tuple looks like ["box", ["1-11", "13-17"]]
      hash.to_a.map do |tuple|
        "#{container_label(tuple[0], tuple[1])} #{tuple[1].join('; ')}"
      end
    end
  end
end
