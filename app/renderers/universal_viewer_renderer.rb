# frozen_string_literal: true
class UniversalViewerRenderer
  IIIF_MANIFEST_ROLE = "https://iiif.io/api/presentation"

  def self.render(document)
    new(document).render
  end

  attr_reader :document
  def initialize(document)
    @document = document
  end

  def render
    return unless valid?
    renderer.render(
      partial_path,
      layout: false,
      locals: { viewer: self }
    )
  end

  def url
    "#{base_url}#?manifest=#{href}"
  end

  delegate :href, to: :digital_object

  private

  def base_url
    Pulfalight.config[:external_universal_viewer_url]
  end

  def digital_object
    document.direct_digital_objects.first
  end

  def partial_path
    "viewers/_universal_viewer"
  end

  def renderer
    ApplicationController.renderer
  end

  def valid?
    digital_object&.role&.starts_with?(IIIF_MANIFEST_ROLE)
  end
end
