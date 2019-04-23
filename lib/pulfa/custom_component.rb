# frozen_string_literal: true

require_relative 'indexing_behavior'

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

      def static_asset_exts
        [".jpg", ".pdf"]
      end

      def static_asset?(href)
        extname = File.extname(href)
        static_asset_exts.include?(extname)
      end
  end
end
