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
    tag.div(children, class: "document-access online-content #{badge_class}")
  end

  private

  def blacklight_icon
    ActionController::Base.helpers.blacklight_icon(:online)
  end

  def children
    icon_span + label
  end

  def icon_span
    tag.span(blacklight_icon, class: "media-body al-online-content-icon", aria: { hidden: true })
  end

  def label
    if document.has_direct_digital_content?
      "HAS ONLINE CONTENT"
    else
      "SOME ONLINE CONTENT"
    end
  end

  def badge_class
    if document.has_direct_digital_content?
      "online-direct-content"
    else
      "online-indirect-content"
    end
  end
end
