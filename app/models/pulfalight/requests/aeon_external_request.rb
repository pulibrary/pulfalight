# frozen_string_literal: true

module Pulfalight
  module Requests
    class AeonExternalRequest < Arclight::Requests::AeonExternalRequest
      include Rails.application.routes.url_helpers

      def config
        @config ||= begin
                      yaml_file_path = "config/aeon.yml"
                      yaml_file = File.read(yaml_file_path)
                      YAML.safe_load(yaml_file)
                    end
      end

      def form_mapping
        super.merge(dynamic_field_mappings)
      end

      def static_mappings
        request_mappings.merge(super)
      end

      def url_params
        return unless config.key?("url_params")

        config["url_params"].to_query
      end

      def url
        return configured_request_url unless url_params

        "#{configured_request_url}?#{url_params}"
      end

      def containers
        []
      end

      def subcontainers
        []
      end

      def eadid
        Array.wrap(@document.eadid).first
      end

      def extent
        Array.wrap(@document.extent).first
      end

      def accessnote
        value = @document.acqinfo.first
        value.gsub(/\t+/, " ").delete("\n")
      end

      def id
        # Generate the request ID here
        @id ||= begin
                  hex_value = SecureRandom.hex(14)
                  dec_value = hex_value.to_i(16)
                  dec_value.to_s
                end
      end
      alias request_id id

      def unitid
        { type: "barcode", value: "32101040795617" }
      end

      def physdesc_number
        @document.physdesc_number.empty? ? ["1"] : @document.physdesc_number
      end

      def physical_location_code
        @document.physical_location_code.first
      end

      def attributes
        {
          callnumber: @document.id,
          referencenumber: eadid,
          title: @document.title.first,
          containers: containers, # add this,
          subcontainers: subcontainers, # add this
          unitid: unitid,
          physloc: @document.physical_location_code.first,
          location: @document.location.first,
          subtitle: @document.subtitle.first,
          itemdate: @document.normalized_date.first,
          itemnumber: id, # This should not be coupled here
          itemvolume: @document.volume.first,
          accessnote: accessnote,
          extent: extent,
          itemurl: url
        }
      end

      private

      def default_url_options
        Rails.application.config.action_controller.default_url_options
      end

      def request_mappings
        {
          Request: id
        }
      end

      # ItemSubTitle_32101037024476=Assorted+Documents
      # ItemTitle_32101037024476=18th-century+French+Documents
      # ItemAuthor_32101037024476=Princeton+University.+Library.%0D%0A++++++++++++++++++++Dept.+of+Special+Collections.
      # ItemDate_32101037024476=1700-1799
      # ReferenceNumber_32101037024476=C0575_c01
      # CallNumber_32101037024476=C0575
      # ItemNumber_32101037024476=32101037024476
      # ItemVolume_32101037024476=Box1
      # Location_32101037024476=mss
      # ItemInfo1_32101037024476=Collection+is+open+for+research+use.
      # ItemInfo2_32101037024476=0.8+linear+feet+%7C+2+boxes
      # ItemInfo3_32101037024476=
      # ItemInfo4_32101037024476=
      # ItemInfo5_32101037024476=https%3A%2F%2Ffindingaids.princeton.edu%2Fcollections%2FC0575%2Fc01
      # Notes=
      # AeonForm=EADRequest
      # RequestType=Loan
      # DocumentType=Manuscript
      # Site=RBSC
      # Location=mss
      # ItemTitle=18th-century+French+Documents
      # GroupingIdentifier=ItemVolume
      # GroupingOption_ReferenceNumber=Concatenate
      # GroupingOption_ItemNumber=Concatenate
      # GroupingOption_ItemDate=FirstValue
      # GroupingOption_CallNumber=FirstValue
      # GroupingOption_ItemVolume=FirstValue
      # GroupingOption_ItemInfo1=FirstValue
      # GroupingOption_Location=FirstValue
      # SubmitButton=Submit+Request

      def default_dynamic_fields
        {
          "Request" => id,
          "CallNumber_#{id}" => @document.id,
          "ItemTitle_#{id}" => @document.title.first,
          "ItemTitle" => @document.title.first,
          "ItemSubTitle_#{id}" => @document.subtitle.first,
          "ItemAuthor_#{id}" => @document.collection_creator,
          "ItemDate_#{id}" => @document.normalized_date.first,
          "ItemNumber_#{id}" => id,
          "ItemVolume_#{id}" => @document.volume.first, # Example: "Box23"
          "ItemInfo1_#{id}" => accessnote, # Example: "Restrictions May Appli. Check Finding Aid."
          "ItemInfo2_#{id}" => extent, # Example: "262.4 linear feet | 648 boxes and 5 oversize folders"
          "ItemInfo3_#{id}" => physdesc_number.first,
          "ItemInfo4_#{id}" => @document.location_note.join(","),
          "ItemInfo5_#{id}" => url,
          "Location_#{id}" => @document.location_code, # Example: mudd
          "Location" => @document.location_code.first,
          "ReferenceNumber_#{id}" => @document.id,
          "DocumentType": "Manuscript",
          "Site": @document.location_code.first,
          "SubmitButton": "Submit Request"
        }
      end

      def dynamic_field_mappings
        default_dynamic_fields
      end

      def configured_request_url
        config.fetch("request_url")
      rescue KeyError => key_error
        Rails.logger.error("No request service URL is configured for Aeon in config/aeon.yml")
        raise key_error
      end
    end
  end
end
