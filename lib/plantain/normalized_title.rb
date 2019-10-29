# frozen_string_literal: true

module Plantain
  # Class for normalizing document titles from a set of title and date values extracted from the EAD Document
  class NormalizedTitle < Arclight::NormalizedTitle
    private

      # Generates the normalized title
      # @return [String]
      def normalize
        result = [title, date].compact.join(", ")
        result = title if result.blank?
        result
      end
  end
end
