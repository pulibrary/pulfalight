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
        @request_id ||= SecureRandom.hex(14).to_i(16).to_s
      end
      alias request_id id

def unitid
        { type: 'barcode', value: '32101040795617' }
      end

      private

      def default_url_options
        Rails.application.config.action_controller.default_url_options
      end

      def request_mappings
        {
          Request: request_id
        }
      end

      def physdesc_number
        @document.physdesc_number.empty? ? ["1"] : @document.physdesc_number
      end

      def physical_location_code
        @document.physical_location_code.first
      end

      def default_dynamic_fields
        {
          "Request" => request_id,
          "CallNumber_#{request_id}" => @document.parent_ids.first,
          "ItemTitle_#{request_id}" => @document.title.first,
          "ItemTitle" => @document.title,
          "ItemSubTitle_#{request_id}" => @document.subtitle.first,
          "ItemAuthor_#{request_id}" => @document.collection_creator,
          "ItemDate_#{request_id}" => @document.normalized_date.first,
          "ItemNumber_#{request_id}" => request_id,
          "ItemVolume_#{request_id}" => @document.volume.first, # Example: "Box23"
          "ItemInfo1_#{request_id}" => @document.acqinfo.first, # Example: "Restrictions May Appli. Check Finding Aid."
          "ItemInfo2_#{request_id}" => @document.extent.first, # Example: "262.4 linear feet | 648 boxes and 5 oversize folders"
          "ItemInfo3_#{request_id}" => physdesc_number.first,
          "ItemInfo4_#{request_id}" => @document.location_note.join(","),
          "ItemInfo5_#{request_id}" => solr_document_url(@document),
          "Location_#{request_id}" => @document.location_code, # Example: mudd
          "Location" => @document.location_code.first,
          "ReferenceNumber_#{request_id}" => @document.eadid.first,
          "DocumentType": "Manuscript",
          "Site": physical_location_code,
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
