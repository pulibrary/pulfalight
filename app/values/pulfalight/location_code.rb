# frozen_string_literal: true

module Pulfalight
  class LocationCode
    def self.config_file_path
      Rails.root.join("config", "location_codes.yml")
    end

    def self.config_file
      @config_file ||= IO.read(config_file_path.to_s)
    end

    def self.config_erb
      @config_erb ||= ERB.new(config_file).result(binding)
    rescue StandardError, SyntaxError => e
      Rails.logger.error("#{config_file_path} was found, but could not be parsed with ERB. \n#{e.inspect}")
      raise(SyntaxError, "#{config_file_path} was found, but could not be parsed with ERB. Please inspect the logs for more information.")
    end

    def self.config
      @config ||= YAML.safe_load(config_erb)
    end

    def self.map(value)
      raise Pulfalight::UnrecognizedLocationError, "Location code #{value} is not supported." unless config.key?(value)

      config[value]
    end

    def self.registered?(value)
      config.key?(value)
    end

    def self.resolve(value)
      code = new(value)
      code.resolve
    end

    attr_reader :value

    def initialize(value)
      @value = value_or_alias(value)
    end

    def to_s
      resolve
    end

    def resolve
      self.class.map(value)
    end

    private

    def value_or_alias(val)
      val.to_s.gsub(/^sca/, "")
    end
  end
end
