# frozen_string_literal: true
Rails.application.config.to_prepare do
  # Add a role attribute to this class
  class Arclight::DigitalObject
    attr_reader :role
    def initialize(label:, href:, role:)
      @label = label.presence || href
      @href = href
      @role = role
    end

    def to_json(*)
      { label: label, href: href, role: role }.to_json
    end

    def self.from_json(json)
      object_data = JSON.parse(json)
      new(label: object_data["label"], href: object_data["href"], role: object_data["role"])
    end
  end
end
