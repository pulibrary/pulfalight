# frozen_string_literal: true

module Pulfalight
  class LocationCode
    def self.config_file_path
      Rails.root.join("config", "location_codes.yml")
    end

    def self.config_file
      @config_file ||= IO.read(config_file_path)
    end

    def self.config_erb
      @config_erb ||= ERB.new(config_file).result(binding)
    rescue StandardError, SyntaxError => e
      raise("#{config_file} was found, but could not be parsed with ERB. \n#{e.inspect}")
    end

    def self.config
      @config ||= YAML.safe_load(config_erb)
    end

    def self.map(value)
      raise("Location code #{value} is not supported.") unless config.key?(value)

      config[value]
    end

    def self.resolve(value)
      code = new(value)
      code.resolve
    end

    attr_reader :value

    def initialize(value)
      @value = value
    end

    # alias to_s resolve
    def to_s
      resolve
    end

    def resolve
      self.class.map(value)
    end
  end
end
