# frozen_string_literal: true

require "logger"
require "traject"
require "traject/nokogiri_reader"
require "traject_plus"
require "traject_plus/macros"
require "arclight/missing_id_strategy"
extend TrajectPlus::Macros
# rubocop:enable Style/MixinUsage
require Rails.root.join("lib", "pulfalight", "traject", "ead2_indexing")
require Rails.root.join("app", "services", "container_id_minter_service")

# =============================
# Each container child document
# <container>
# =============================

# Module for providing recursion over components
module ContainerIndexer
  self.class.include(Pulfalight::Ead2Indexing)

  def add_container_indexing_steps
    configure_before

    to_field "id" do |record, accumulator|
      minter = ContainerIdMinterService.new(node: record)
      minted_id = minter.mint
      accumulator << minted_id
    end

    to_field "type_ssim" do |record, accumulator|
      attribute = record.attribute("type")
      accumulator << attribute.value if attribute
    end

    to_field "parent_ssim" do |record, accumulator|
      attribute = record.attribute("parent")
      accumulator << attribute.value if attribute
    end

    configure_after
  end
end

# Build the steps
self.class.include(ContainerIndexer)
add_container_indexing_steps
