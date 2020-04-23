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
require Rails.root.join("app", "services", "code_resolver")

# Module for providing recursion over components
module PhysicalHoldingIndexer
  self.class.include(Pulfalight::Ead2Indexing)

  def add_physical_holding_indexing_steps
    configure_before

    to_field "box_number_ssi" do |record, accumulator|
      unitid_element = record.at_xpath("./did/container[@type='box']")
      accumulator << unitid_element&.text&.to_i
    end
    to_field "box_number_ssm" do |_record, accumulator, context|
      box_numbers = context.output_hash.fetch("box_number_ssi", [])

      accumulator.concat box_numbers.map(&:to_s)
    end

    to_field "barcode_ssi" do |record, accumulator|
      unitid_element = record.at_xpath("./did/unitid[@type='barcode']")
      accumulator << unitid_element&.text&.to_i
    end
    to_field "barcode_ssm" do |_record, accumulator, context|
      barcodes = context.output_hash.fetch("barcode_ssi", [])

      accumulator.concat barcodes.map(&:to_s)
    end

    to_field "physical_location_code_ssm" do |record, accumulator|
      unitid_element = record.at_xpath("./did/physloc[@type='code']")
      accumulator << unitid_element&.text
    end

    to_field "physical_location_ssm" do |_record, accumulator, context|
      location_codes = context.output_hash.fetch("physical_location_code_ssm", [])
      location_code = location_codes.first
      next unless location_code

      location = Pulfalight::PhysicalLocationResolver.resolve(location_code)
      accumulator << location
    end

    to_field "components" do |record, accumulator, context|
      child_components = record.xpath("./*[is_component(.)]", Pulfalight::Ead2Indexing::NokogiriXpathExtensions.new)
      child_components.each do |child_component|
        component_indexer = build_component_indexer(context)
        output = component_indexer.map_record(child_component)
        accumulator << output
      end
    end

    configure_after
  end
end

# Build the steps
self.class.include(PhysicalHoldingIndexer)
add_physical_holding_indexing_steps
