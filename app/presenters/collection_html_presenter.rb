# frozen_string_literal: true

class CollectionHtmlPresenter < CollectionPresenter
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  def notes
    values = @document.collection_notes
    safe_join(values.map { |paragraph| content_tag(:p, paragraph) })
  end
end
