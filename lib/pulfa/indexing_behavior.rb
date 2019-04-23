# frozen_string_literal: true

require_relative 'indexing_behavior'
require_relative 'year_range'
require_relative 'normalized_date'

module Pulfa
  module IndexingBehavior
    def add_normalized_title(solr_doc)
      normalized_date = NormalizedDate.new(unitdate_inclusive.first, unitdate_bulk.first, unitdate_other.first)
      date_values = normalized_date.to_s

      titles = solr_doc['title_ssm']
      first_title = titles.try(:first)
      normalized_title = Pulfa::NormalizedTitle.new(first_title, date_values)
      title_value = normalized_title.to_s

      solr_doc['normalized_title_ssm'] = [title_value]
      solr_doc['normalized_date_ssm'] = [date_values]

      title_value
    end

    # A mixin intended to share indexing behavior between
    # the CustomDocument and CustomComponent classes
    def unitdate_for_range
      range = YearRange.new
      return range if normal_unit_dates.blank?
      range << range.parse_ranges(normal_unit_dates)
      range
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
  end
end
