# frozen_string_literal: true
class UniversalViewer
  def initialize(document)
    @document = document
  end

  def to_partial_path
    "viewers/_universal_viewer"
  end

  def url
    "#{base_url}#?manifest=#{manifest_url}"
  end

  def base_url
    Plantain.config[:external_universal_viewer_url]
  end

  def manifest_url
    @document.digital_objects.first.href
  end
end
