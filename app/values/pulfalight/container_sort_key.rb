# frozen_string_literal: true

module Pulfalight
  class ContainerSortKey
    # Process a box or folder value to use in the box_folder_sort_si field.
    # 1. Capture any numbers and left pad to help with sorting.
    #    For example, "2" should sort before "10".
    #    "2" < "10" == false
    #    "0000000002" < "0000000010" ==true
    # 2. Keep any additional characters, strip, and downcase.
    #    " B-001180 " becomes "b-0000001180"
    #    "1-3" becomes "0000000001-0000000003"
    def self.build(value)
      value.to_s.strip.downcase.gsub(/\d+/) { |digits| digits.rjust(10, "0") }
    end
  end
end
