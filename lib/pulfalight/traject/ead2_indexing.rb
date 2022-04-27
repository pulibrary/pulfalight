# frozen_string_literal: true

module Pulfalight
  module Ead2Indexing
    NAME_ELEMENTS = %w[corpname famname name persname].freeze

    SEARCHABLE_NOTES_FIELDS = %w[
      accessrestrict
      accruals
      altformavail
      appraisal
      arrangement
      bibliography
      custodhist
      fileplan
      note
      odd
      originalsloc
      otherfindaid
      phystech
      processinfo
      relatedmaterial
      scopecontent
      separatedmaterial
      userestrict
    ].freeze

    DID_SEARCHABLE_NOTES_FIELDS = %w[
      abstract
      materialspec
      physloc
    ].freeze

    def configure_before
      settings do
        provide "reader_class_name", "Traject::NokogiriReader"
        provide "solr_writer.commit_on_close", "false"
        provide "repository", ENV["REPOSITORY_ID"]
        provide "logger", Logger.new($stderr)
      end

      each_record do |_record, context|
        next unless settings["repository"]

        repository = Arclight::Repository.find_by(
          slug: settings["repository"]
        )

        context.clipboard[:repository] = repository.name unless repository.nil?
      end
    end

    def configure_after
      each_record do |_record, context|
        context.output_hash["components"] &&= context.output_hash["components"].select { |c| c.keys.any? }
      end
    end

    def component_indexer
      @component_indexer ||=
        begin
          config_file_path = Rails.root.join("lib", "pulfalight", "traject", "ead2_component_config.rb")
          Traject::Indexer::NokogiriIndexer.new.tap do |i|
            i.load_config_file(config_file_path)
          end
        end
    end

    # Returns if DAO should be indexed.
    # @param [Nokogiri::XML::Element] dao
    # @return [Boolean]
    def index_dao?(dao)
      href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
      return true if href.blank?
      # Exclude DAOs that are relative paths.
      href.include?("://")
    end

    def build_bioghist(accumulator)
      sanitizer = Rails::Html::SafeListSanitizer.new

      accumulator.map! do |element|
        name_nodes = element.xpath('./note[@label="personal-name"]')
        name_nodes.each do |name_node|
          name_node.name = "p"
          name_node["class"] = name_node["label"]
          name_node.delete("label")
        end

        head_nodes = element.xpath("./head")
        head_nodes.each(&:remove)

        element_html = element.to_html
        sanitized = sanitizer.sanitize(element_html, tags: %w[extref p])
        anchored = sanitized.gsub("extref", "a")
        anchored.strip
      end
    end

    ##
    # Used for evaluating xpath components to find
    class NokogiriXpathExtensions
      # rubocop:disable Naming/PredicateName, Style/FormatString
      def is_component(node_set)
        node_set.find_all do |node|
          component_elements = (1..12).map { |i| "c#{'%02d' % i}" }
          component_elements.push "c"
          component_elements.include? node.name
        end
      end
      # rubocop:enable Naming/PredicateName, Style/FormatString
    end
  end
end
