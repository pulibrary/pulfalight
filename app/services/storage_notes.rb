# frozen_string_literal: true
class StorageNotes
  def self.for(location_code)
    return StorageNotes::Combined.new(location_code) if location_code.is_a?(Array) && location_code.length > 1
    new(Array.wrap(location_code).first)
  end

  attr_reader :location_code
  def initialize(location_code)
    @location_code = location_code
  end

  def config
    @config ||= YAML.safe_load(Rails.root.join("config", "storage_notes.yml").read, [], [], true)
  end

  def to_a
    Array.wrap(config[location_code&.downcase] || [])
  end

  class Combined
    attr_reader :location_codes
    def initialize(location_codes)
      @location_codes = location_codes
    end

    def to_a
      [
        "This collection is stored at #{location_strings.to_sentence}."
      ]
    end

    def location_strings
      valid_codes.map do |code|
        Pulfalight::LocationCode.map(code)
      end
    end

    def valid_codes
      location_codes.select do |code|
        Pulfalight::LocationCode.registered?(code)
      end
    end
  end
end
