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

# =============================
# Each container child document
# <container>
# =============================

# Module for providing recursion over components
module ContainerIndexer
  self.class.include(Pulfalight::Ead2Indexing)

  def hash_algorithm
    Digest::SHA1
  end

  COMPONENT_NODE_NAME_REGEX = /^c\d{,2}$/.freeze

  def add_container_indexing_steps
    configure_before

    to_field "id" do |record, accumulator|
      # This needs to become a service class
      ancestor_tree = record.ancestors.map do |ancestor|
        if COMPONENT_NODE_NAME_REGEX.match?(ancestor.name)
          ancestor_siblings = ancestor.parent.children.select { |n| n.name =~ COMPONENT_NODE_NAME_REGEX }
          index = ancestor_siblings.index(ancestor)
          "#{ancestor.name}#{index}"
        else
          ancestor.name
        end
      end

      siblings = record.parent.children.select { |n| n.name =~ COMPONENT_NODE_NAME_REGEX }
      current_index = siblings.index(record)
      absolute_xpath = "#{[ancestor_tree.reverse, record.name].flatten.join('/')}#{current_index}"
      accumulator << hash_algorithm.hexdigest(absolute_xpath).prepend("al_")
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
