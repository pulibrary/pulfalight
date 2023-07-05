# frozen_string_literal: true

class OnlineContentBadge
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::TagHelper

  attr_reader :document, :icon_only
  def initialize(document, icon_only: false)
    @document = document
    @icon_only = icon_only
  end

  def render
    return unless document.has_digital_content?
    if icon_only
      tag.span(icon_span, class: "online-content #{badge_class}", title: label.capitalize)
    else
      tag.div(children, class: "document-access online-content #{badge_class}")
    end
  end

  def icon_span
    tag.span(blacklight_icon, class: "media-body", aria: { hidden: true })
  end

  private

  def blacklight_icon
    ActionController::Base.helpers.blacklight_icon(:online)
  end

  def children
    icon_span + label
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
