# frozen_string_literal: true

module Pulfalight
  class Parents < Arclight::Parents
    def eadid
      Arclight::NormalizedId.new(@eadid).to_s
    rescue Arclight::Exceptions::IDNotFound
      SecureRandom.hex(14)
    end
  end
end
