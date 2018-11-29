# frozen_string_literal: true

module Pulfa
  class CustomDocument < Arclight::CustomDocument

    class NormalizedTitle < Arclight::NormalizedTitle
      private

      # This overrides the Arclight::NormalizedTitle#normalize in order to ensure that titles without parsed dates are handled without raising a Arclight::Exceptions::TitleNotFound
      def normalize

        result = [title, date].compact.join(', ')
        if result.blank?
          result = title
        end
        result
      end
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
  end
end
