
# frozen_string_literal: true
module Pulfa
  class NormalizedTitle < Arclight::NormalizedTitle
    private

      def normalize
        result = [title, date].compact.join(', ')
        # raise Arclight::Exceptions::TitleNotFound if result.blank?
        result = title if result.blank?
        result
      end
  end
end
