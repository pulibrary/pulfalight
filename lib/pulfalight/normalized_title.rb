# frozen_string_literal: true

module Pulfalight
  # Class for normalizing document titles from a set of title and date values extracted from the EAD Document
  class NormalizedTitle < Arclight::NormalizedTitle
    private

    # Generates the normalized title
    # @return [String]
    def normalize
      title_with_stripped_date = title.gsub(/, \d{4}-\d{4}/, "")
      result = [title_with_stripped_date, date].compact.join(", ")
      result = title if result.blank?
      result
    end
  end
end
