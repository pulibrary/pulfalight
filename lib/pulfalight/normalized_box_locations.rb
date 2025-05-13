# frozen_string_literal: true

module Pulfalight
  # Class for normalizing container locations to assemble the Magic Physloc Note
  # It accepts a hash that looks like this:
  # {
  #   "hsvm" => {"box" => ["1", "323", "2", "3", "4", "5", "6"], "volume" => ["42", "43", "44", "45"]},
  #   "mss" => {"box" => ["12", "20", "21", "30", "31"]},
  #   "rcpxm" => {"box" => ["266", "114", "105", "106"]}
  # }
  # ... and turns it into a json string that looks like this:
  # { "Firestone Library Vault" => ["Boxes 1-6; 323", "Volumes 42-45"] }
  #
  # if there are items they can be summarized as "X individual items"
  class NormalizedBoxLocations
    # @param [Hash] container_locations
    def initialize(container_locations, collapse_items: false)
      @normalized_locations = {}

      container_locations.each do |location, types_hash|
        types_hash.each do |type, indicators_array|
          key = translate_location(location)
          @normalized_locations[key] =
            @normalized_locations.fetch(key, []).append(container_summary_string(indicators_array, type, collapse_items))
        end
      end
    end

    def locations
      @normalized_locations.keys
    end

    def to_h
      @normalized_locations
    end

    private

    def translate_location(location)
      "#{Pulfalight::LocationCode.resolve(location)} (#{location})"
    rescue Pulfalight::UnrecognizedLocationError
      location
    end

    ##
    # Given an array of container numbers:
    # 1. Remove any that are not integers
    # 2. Sort and group the integers into ranges
    # 3. Consolidate any ranges
    # 4. Re-add the non-integer container numbers
    # Ranges for abid'd (e.g. "P-094623") containers are computed in summary_storage_note_presenter.rb
    # @param [<String>] numbers
    # @return <String>
    def container_summary_string(numbers, type, collapse_items)
      unless collapse_items && type == "item"
        non_numeric_ids = numbers.reject { |a| a.to_i.to_s == a }
        ranges = generate_range_strings(numbers)
        containers_set = ranges.map { |a| consolidate_single_container_ranges(a) } | non_numeric_ids
        summary = type_ranges_summary(type, containers_set)
        return summary unless summary.length > 32_766 # solr field max
      end
      # if we have items and the collapse flag, or the summary was too long,
      # return a count
      "#{numbers.count} individual #{'item'.pluralize(numbers.count)}"
    end

    def generate_range_strings(numbers)
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
      ranges
    end

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

    def type_ranges_summary(type, ranges)
      "#{container_label(type, ranges)} #{ranges.join('; ')}"
    end
  end
end
