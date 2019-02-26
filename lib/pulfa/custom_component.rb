# frozen_string_literal: true
module Pulfa
  class CustomComponent < Arclight::CustomComponent
    include IndexingBehavior

    def initialize
      super
      @dao_elements = {}
      @digital_objects = {}
    end

    private

      def dao_elements(prefix = "/")
        @dao_elements[prefix] ||= ng_xml.xpath("#{prefix}/dao[@href]").to_a
      end
  end
end
