module Pulfa
  class CustomComponent < Arclight::CustomComponent
    class NormalizedTitle < Arclight::NormalizedTitle
      private

      def normalize

        result = [title, date].compact.join(', ')
        # raise Arclight::Exceptions::TitleNotFound if result.blank?
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
