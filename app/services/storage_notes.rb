# frozen_string_literal: true
class StorageNotes
  def self.for(location_code)
    new(location_code)
  end

  attr_reader :location_code
  def initialize(location_code)
    @location_code = location_code
  end

  def config
    @config ||= YAML.safe_load(Rails.root.join("config", "storage_notes.yml").read, [], [], true)
  end

  def to_a
    Array.wrap(config[location_code] || [])
  end
end
