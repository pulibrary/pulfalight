# frozen_string_literal: true
class UniversalViewer
  IIIF_MANIFEST_ROLE = "https://iiif.io/api/presentation"

  attr_reader :document
  def initialize(document)
    @document = document
  end

  def to_partial_path
    if digital_object.role&.starts_with? IIIF_MANIFEST_ROLE
      "viewers/_universal_viewer"
    else
      "viewers/_simple_link"
    end
  end

  def url
    "#{base_url}#?manifest=#{href}"
  end

  def base_url
    Pulfalight.config[:external_universal_viewer_url]
  end

  def digital_object
    document.direct_digital_objects.first
  end
  delegate :href, to: :digital_object
  delegate :label, to: :digital_object
end
