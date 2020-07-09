# frozen_string_literal: true

class ComponentHtmlPresenter < ComponentPresenter
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  def collection_notes
    values = @document.collection_notes
    safe_join(values.map { |paragraph| content_tag(:p, paragraph) })
  end
end
