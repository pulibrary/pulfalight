# frozen_string_literal: true

class OnlineContentBanner
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  attr_reader :document
  def initialize(document)
    @document = document
  end

  def render
    return unless document.has_digital_content?
    if document.has_direct_digital_content?
      "All materials in this collection are available online."
    else
      "Some materials in this collection are available online."
    end
  end
end
