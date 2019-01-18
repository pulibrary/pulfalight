# frozen_string_literal: true

module Pulfa
  class CustomDocument < Arclight::CustomDocument
    class NormalizedTitle < Arclight::NormalizedTitle
      private

        # This overrides the Arclight::NormalizedTitle#normalize in order to ensure that titles without parsed dates are handled without raising a Arclight::Exceptions::TitleNotFound
        def normalize
          result = [title, date].compact.join(', ')
          result = title if result.blank?
          result
        end
    end

    def initialize
      super
      @dao_elements = {}
      @digital_objects = {}
    end

    def add_normalized_title(solr_doc)
      dates = Arclight::NormalizedDate.new(unitdate_inclusive.first, unitdate_bulk.first, unitdate_other.first).to_s
      begin
        title = NormalizedTitle.new(solr_doc['title_ssm'].try(:first), dates).to_s
      rescue
        title = solr_doc['title_ssm']
      end
      solr_doc['normalized_title_ssm'] = [title]
      solr_doc['normalized_date_ssm'] = [dates]
      title
    end

    def add_digital_content(prefix:, solr_doc:)
      field_name = Solrizer.solr_name('digital_objects', :displayable)
      values = digital_objects(prefix: prefix)
      return if values.blank?

      solr_doc[field_name] = values
    end

    def digital_objects(prefix: "/")
      return @digital_objects[prefix] if @digital_objects[prefix]
      elements = dao_elements(prefix)

      values = elements.map do |element|
        label = element.attributes['title'].try(:value) || element.xpath('daodesc/p').try(:text)
        href = (element.attributes['href'] || element.attributes['xlink:href']).try(:value)

        next if static_asset?(href)
        Arclight::DigitalObject.new(label: label, href: href).to_json
      end
      @digital_objects[prefix] = values.compact
    end

    def online_content?
      values = digital_objects
      values.present?
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
