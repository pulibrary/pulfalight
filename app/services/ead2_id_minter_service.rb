# frozen_string_literal: true

class Ead2IdMinterService
  # This is intended to be generalized for any XML element
  NODE_NAME_REGEX = /^.+$/.freeze

  def self.hash_algorithm
    Digest::SHA1
  end

  def self.select_component_siblings(node:)
    node.parent.children.select { |n| n.name =~ NODE_NAME_REGEX }
  end

  def initialize(node:)
    @node = node
  end

  def mint
    hashed = self.class.hash_algorithm.hexdigest(absolute_xpath)
    hashed.prepend("al_")
  end

  private

    def ancestors
      @node.ancestors.reject { |n| n.is_a?(Nokogiri::XML::Document) }
    end

    def ancestor_tree
      ancestors.map do |ancestor|
        ancestor_siblings = self.class.select_component_siblings(node: ancestor)
        index = ancestor_siblings.index(ancestor)
        "#{ancestor.name}#{index}"
      end
    end

    def siblings
      self.class.select_component_siblings(node: @node)
    end

    def current_index
      siblings.index(@node)
    end

    def absolute_xpath
      "#{[ancestor_tree.reverse, @node.name].flatten.join('/')}#{current_index}"
    end
end
