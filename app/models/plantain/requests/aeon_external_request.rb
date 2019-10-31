# frozen_string_literal: true

module Plantain
  module Requests
    class AeonExternalRequest < Arclight::Requests::AeonExternalRequest
      def form_mapping
        super.merge(dynamic_field_mappings)
      end

      def static_mappings
        request_mappings.join(super)
      end

      private

        def request_id
          # Generate the request ID here
        end

        def request_mappings
          {
            :Request => request_id
          }
        end


        def self.default_dynamic_fields
          {
            "CallNumber_#{request_id}" => @document.parentid,

            "ItemTitle_#{request_id}" => @document.title,
            "ItemSubTitle_#{request_id}" => @document.sub_title,
            "ItemAuthor_#{request_id}" => @document.author,
            "ItemDate_#{request_id}" => @document.date,
            "ItemNumber_#{request_id}" => request_id,
            "ItemVolume_#{request_id}" => @document.volume,

            "ItemInfo1_#{request_id}" => @document.access,
            "ItemInfo2_#{request_id}" => @document.extent,
            "ItemInfo3_#{request_id}" => 1, # Is this the number of items being requested?
            "ItemInfo4_#{request_id}" => ",", # I am uncertain as to where this is generated
            "ItemInfo5_#{request_id}" => solr_document_url(@document),

            "Location_#{request_id}" => @document.repository,
            "ReferenceNumber_#{request_id}" => @document.eadid
          }
        end

=begin
      4: {name: "ItemDate_32101037692462", value: "1890-1891"}
      5: {name: "ReferenceNumber_32101037692462", value: "C0959_c001"}
      6: {name: "CallNumber_32101037692462", value: "C0959"}
      7: {name: "ItemNumber_32101037692462", value: "32101037692462"}
      8: {name: "ItemVolume_32101037692462", value: "Box1"}
      9: {name: "Location_32101037692462", value: "mss"}
      10: {name: "ItemInfo1_32101037692462", value: "Collection is open for research use."}
      11: {name: "ItemInfo2_32101037692462", value: "0.2 linear feet | 1 half-size archival box"}
      12: {name: "ItemInfo3_32101037692462", value: " 1"}
      13: {name: "ItemInfo4_32101037692462", value: ","}
      14: {name: "ItemInfo5_32101037692462", value: "https://findingaids.princeton.edu/collections/C0959"}
=end

        def dynamic_field_mappings
          configured_dynamic_fields = config['request_mappings']['dynamic_fields']
          self.class.default_dynamic_fields.merge(configured_dynamic_fields)
        end
    end
  end
end
