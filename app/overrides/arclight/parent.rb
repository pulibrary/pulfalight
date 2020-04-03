# frozen_string_literal: true

module Arclight
  # Copied and overridden from Arclight to handle the fact that we don't prefix
  # our components with eadid.
  class Parent
    attr_reader :id, :label, :eadid, :level
    def initialize(id:, label:, eadid:, level:)
      @id = id
      @label = label
      @eadid = eadid
      @level = level
    end

    def global_id
      id
    end
  end
end
