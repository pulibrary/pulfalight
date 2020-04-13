# frozen_string_literal: true

module Pulfalight
  class Parents < Arclight::Parents
    def self.normalized_id_class
      Arclight::NormalizedId
    end

    def eadid
      self.class.normalized_id_class.new(@eadid).to_s
    rescue Arclight::Exceptions::IDNotFound
      SecureRandom.hex(14)
    end
  end
end
