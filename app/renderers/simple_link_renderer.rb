# frozen_string_literal: true
class SimpleLinkRenderer
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

  delegate :href, to: :digital_object

  private

  def digital_object
    document.direct_digital_objects.first
  end

  def partial_path
    "viewers/_simple_link"
  end

  def renderer
    ApplicationController.renderer
  end

  def valid?
    digital_object && digital_object&.role.nil?
  end
end
