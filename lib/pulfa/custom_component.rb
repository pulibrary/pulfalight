# frozen_string_literal: true
module Pulfa
  class CustomComponent < Arclight::CustomComponent
    class NormalizedTitle < Arclight::NormalizedTitle
      private

        def normalize
          result = [title, date].compact.join(', ')
          # raise Arclight::Exceptions::TitleNotFound if result.blank?
          result = title if result.blank?
          result
        end
    end

    def add_normalized_title(solr_doc)
      normalized_date = Arclight::NormalizedDate.new(unitdate_inclusive.first, unitdate_bulk.first, unitdate_other.first)
      date_values = normalized_date.to_s

      titles = solr_doc['title_ssm']
      first_title = titles.try(:first)
      normalized_title = NormalizedTitle.new(first_title, date_values)
      title_value = normalized_title.to_s

      solr_doc['normalized_title_ssm'] = [title_value]
      solr_doc['normalized_date_ssm'] = [date_values]

      title_value
    end
  end
end
