# frozen_string_literal: true

require "logger"
require "traject"
require "json"
require "traject/nokogiri_reader"
require "traject_plus"
require "traject_plus/macros"
require "arclight/level_label"
require "arclight/normalized_date"
require "arclight/normalized_title"
require "active_model/conversion" ## Needed for Arclight::Repository
require "active_support/core_ext/array/wrap"
require "arclight/year_range"
require "arclight/repository"
require "arclight/missing_id_strategy"
require "arclight/traject/nokogiri_namespaceless_reader"
require_relative "../normalized_title"
require_relative "../normalized_date"
require_relative "../normalized_box_locations"
require_relative "../year_range"
require_relative "../missing_repository_error"
require Rails.root.join("lib", "pulfalight", "traject", "ead2_indexing")
require Rails.root.join("app", "values", "pulfalight", "location_code")
require Rails.root.join("app", "values", "pulfalight", "physical_location_code")

# rubocop:disable Style/MixinUsage
extend TrajectPlus::Macros
# rubocop:enable Style/MixinUsage

self.class.include(Pulfalight::Ead2Indexing)

# Configure the settings before the Document is indexed
configure_before

# ==================
# Top level document
# ==================

# rubocop:disable Performance/StringReplacement
# TODO: These should be combined into a single method
to_field "id", extract_xpath("/ead/eadheader/eadid", to_text: false) do |_record, accumulator|
  string_array = accumulator.map(&:text)
  string_array = string_array.map { |a| a.gsub(".", "-") }
  string_array = string_array.map { |a| a.split("|").first }
  accumulator.replace(string_array)
end
to_field "ead_ssi", extract_xpath("/ead/eadheader/eadid", to_text: false) do |_record, accumulator|
  string_array = accumulator.map(&:text)
  string_array = string_array.map { |a| a.gsub(".", "-") }
  string_array = string_array.map { |a| a.split("|").first }
  accumulator.replace(string_array)
end
# rubocop:enable Performance/StringReplacement

to_field "title_filing_si", extract_xpath('/ead/eadheader/filedesc/titlestmt/titleproper[@type="filing"]')
to_field "title_ssm", extract_xpath("/ead/archdesc/did/unittitle")
to_field "title_teim", extract_xpath("/ead/archdesc/did/unittitle")
to_field "subtitle_ssm", extract_xpath("/ead/archdesc/did/unittitle")
to_field "subtitle_teim", extract_xpath("/ead/archdesc/did/unittitle")
to_field "ark_tsim", extract_xpath("/ead/eadheader/eadid/@url", to_text: false) do |_record, accumulator|
  accumulator.replace(accumulator.map(&:text))
end

# Use normal attribute value of unitdate. Text values are unreliable and potentially very different.
# E.g. <unitdate normal="1670/1900" type="inclusive">1600s-1900s</unitdate>
# returns a date range of 1600-1900 rather than 1670-1900.
to_field "unitdate_ssm", extract_xpath("/ead/archdesc/did/unitdate/@normal", to_text: false) do |_record, accumulator|
  accumulator.replace [accumulator&.first&.value]
end
to_field "unitdate_bulk_ssim", extract_xpath('/ead/archdesc/did/unitdate[@type="bulk"]/@normal', to_text: false) do |_record, accumulator|
  accumulator.replace [accumulator&.first&.value]
end
to_field "unitdate_inclusive_ssm", extract_xpath('/ead/archdesc/did/unitdate[@type="inclusive"]')

to_field "unitdate_other_ssim", extract_xpath("/ead/archdesc/did/unitdate[not(@type)]")

# All top-level docs treated as 'collection' for routing / display purposes
to_field "level_ssm" do |_record, accumulator|
  accumulator << "collection"
end

# Keep the original top-level archdesc/@level for Level facet in addition to 'Collection'
to_field "level_sim" do |record, accumulator|
  archdesc = record.at_xpath("/ead/archdesc")
  unless archdesc.nil?

    level = archdesc.attribute("level")&.value
    other_level = archdesc.attribute("otherlevel")&.value

    accumulator << Arclight::LevelLabel.new(level, other_level).to_s
    accumulator << "Collection" unless level == "collection"
  end
end

to_field "unitid_ssm", extract_xpath("/ead/archdesc/did/unitid")
to_field "unitid_teim", extract_xpath("/ead/archdesc/did/unitid")

to_field "physloc_code_ssm" do |record, accumulator|
  record.xpath("/ead/archdesc/did/physloc").each do |physloc_element|
    code = Pulfalight::LocationCode.new(physloc_element.text).value
    if Pulfalight::PhysicalLocationCode.registered?(code)
      physical_location_code = Pulfalight::PhysicalLocationCode.resolve(code)
      accumulator << physical_location_code.to_s
    end
  end
end

to_field "summary_storage_note_ssm" do |record, accumulator|
  locations = {}

  record.xpath("//container[not(@parent)]").each do |container|
    # make the data look like this:
    # "hsvm" => {"box" => ["1", "323", "2", "3", "4", "5", "6"], "volume" => ["42", "43", "44", "45"]}
    container_type = container["type"]
    location_code = container["altrender"]
    location_hash = locations.fetch(location_code, {})
    location_hash[container_type] = location_hash.fetch(container_type, [])
    location_hash[container_type] << container.text
    locations[location_code] = location_hash
  end

  json = Pulfalight::NormalizedBoxLocations.new(locations, collapse_items: true).to_h.to_json
  accumulator << json
end

to_field "location_code_ssm" do |record, accumulator|
  values = []
  record.xpath("/ead/archdesc/did/physloc").each do |physloc_element|
    code = Pulfalight::LocationCode.new(physloc_element.text).value
    if Pulfalight::LocationCode.registered?(code)
      location_code = Pulfalight::LocationCode.resolve(code)
      values << location_code.to_s
    end
  end

  accumulator.concat(values.uniq)
end

to_field "location_note_ssm" do |record, accumulator|
  record.xpath("/ead/archdesc/did/physloc").each do |physloc_element|
    code = Pulfalight::LocationCode.new(physloc_element.text).value
    accumulator << physloc_element.text if !Pulfalight::PhysicalLocationCode.registered?(code) && !Pulfalight::LocationCode.registered?(code)
  end
end

to_field "collection_unitid_ssm", extract_xpath("/ead/archdesc/did/unitid")

to_field "normalized_title_ssm" do |_record, accumulator, context|
  dates = Pulfalight::NormalizedDate.new(
    context.output_hash["unitdate_inclusive_ssm"],
    context.output_hash["unitdate_bulk_ssim"],
    context.output_hash["unitdate_other_ssim"]
  ).to_s
  titles = context.output_hash["title_ssm"]
  if titles.present?
    title = titles.first
    accumulator << Pulfalight::NormalizedTitle.new(title, dates).to_s
  end
end

to_field "normalized_date_ssm" do |_record, accumulator, context|
  accumulator << Pulfalight::NormalizedDate.new(
    context.output_hash["unitdate_inclusive_ssm"],
    context.output_hash["unitdate_bulk_ssim"],
    context.output_hash["unitdate_other_ssim"]
  ).to_s
end

to_field "collection_ssm" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end
to_field "collection_sim" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end
to_field "collection_ssi" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end
to_field "collection_title_tesim" do |_record, accumulator, context|
  accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
end

to_field "repository_ssm" do |_record, accumulator, context|
  repository = context.clipboard[:repository]
  raise Pulfalight::MissingRepositoryError unless repository
  accumulator << repository
end

to_field "repository_sim" do |_record, accumulator, context|
  accumulator << context.clipboard[:repository]
end

to_field "repository_code_ssm" do |_record, accumulator, context|
  accumulator << context.settings[:repository]
end

to_field "geogname_ssm", extract_xpath("/ead/archdesc/controlaccess/geogname")
to_field "geogname_sim", extract_xpath("/ead/archdesc/controlaccess/geogname")

to_field "creator_ssm", extract_xpath("/ead/archdesc/did/origination[@label='Creator']") do |_record, accumulator|
  accumulator.uniq!
end
to_field "creator_sim", extract_xpath("/ead/archdesc/did/origination[@label='Creator']") do |_record, accumulator|
  accumulator.uniq!
end
to_field "creator_ssim", extract_xpath("/ead/archdesc/did/origination[@label='Creator']") do |_record, accumulator|
  accumulator.uniq!
end
to_field "creator_sort" do |record, accumulator|
  accumulator << record.xpath("/ead/archdesc/did/origination[@label='Creator']").map { |c| c.text.strip }.uniq.join(", ")
end

to_field "creator_persname_ssm", extract_xpath("/ead/archdesc/did/origination/persname[@role='cre']")
to_field "creator_persname_ssim", extract_xpath("/ead/archdesc/did/origination/persname[@role=\"cre\"]")
to_field "creator_corpname_ssm", extract_xpath("/ead/archdesc/did/origination/corpname[@role='cre']")
to_field "creator_corpname_sim", extract_xpath("/ead/archdesc/did/origination/corpname[@role='cre']")
to_field "creator_corpname_ssim", extract_xpath("/ead/archdesc/did/origination/corpname[@role='cre']")
to_field "creator_famname_ssm", extract_xpath("/ead/archdesc/did/origination/famname[@role='cre']")
to_field "creator_famname_ssim", extract_xpath("/ead/archdesc/did/origination/famname[@role='cre']")

to_field "persname_sim", extract_xpath("//persname")

to_field "creators_ssim" do |_record, accumulator, context|
  accumulator.concat context.output_hash["creator_persname_ssm"] if context.output_hash["creator_persname_ssm"]
  accumulator.concat context.output_hash["creator_corpname_ssm"] if context.output_hash["creator_corpname_ssm"]
  accumulator.concat context.output_hash["creator_famname_ssm"] if context.output_hash["creator_famname_ssm"]
end

to_field "collectors_ssim", extract_xpath("/ead/archdesc/did/origination/*[@role='col']")

to_field "places_sim", extract_xpath("/ead/archdesc/controlaccess/geogname")
to_field "places_ssim", extract_xpath("/ead/archdesc/controlaccess/geogname")
to_field "places_ssm", extract_xpath("/ead/archdesc/controlaccess/geogname")

to_field "access_terms_ssm", extract_xpath('/ead/archdesc/userestrict/*[local-name()!="head"]')

to_field "acqinfo_ssim", extract_xpath('/ead/archdesc/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssim", extract_xpath('/ead/archdesc/descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_teim", extract_xpath('/ead/archdesc/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_teim", extract_xpath('/ead/archdesc/descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash.fetch("acqinfo_ssim", []))
end

to_field "access_subjects_ssim" do |record, accumulator|
  values = record.xpath("/ead/archdesc/controlaccess")
  values = values.map do |element|
    %w[subject function occupation genreform].map do |selector|
      element.xpath(".//#{selector}").map(&:text).map(&:strip)
    end
  end.flatten!
  values = ChangeTheSubject.fix(subject_terms: values, separators: [" -- ", "--"]).sort
  accumulator.concat(values)
end

# For search only
to_field "archaic_access_subjects_ssim" do |record, accumulator, context|
  values = record.xpath("/ead/archdesc/controlaccess")
  values = values.map do |element|
    %w[subject function occupation genreform].map do |selector|
      element.xpath(".//#{selector}").map(&:text).map(&:strip)
    end
  end.flatten!
  processed_values = context.output_hash.fetch("access_subjects_ssim", [])

  # Return array of original archaic values
  accumulator.concat(Array.wrap(values) - processed_values)
end

to_field "access_subjects_ssm" do |_record, accumulator, context|
  accumulator.concat Array.wrap(context.output_hash["access_subjects_ssim"])
end

to_field "has_online_content_ssim", extract_xpath(".//dao", to_text: false) do |_record, accumulator|
  accumulator.replace([accumulator.any? { |dao| index_dao?(dao) }])
end

to_field "has_direct_online_content_ssim", extract_xpath("/ead/archdesc/did/dao|/ead/archdesc/dao", to_text: false) do |_record, accumulator|
  accumulator.replace([accumulator.any? { |dao| index_dao?(dao) }])
end

to_field "digital_objects_ssm", extract_xpath("/ead/archdesc/did/dao|/ead/archdesc/dao", to_text: false) do |_record, accumulator, context|
  accumulator.map! do |dao|
    label = dao.attributes["title"]&.value ||
            dao.xpath("daodesc/p")&.text
    href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
    role = (dao.attributes["role"] || dao.attributes["xlink:role"])&.value
    Arclight::DigitalObject.new(label: label, href: href, role: role).to_json
  end.compact
  # Copy to direct_digital_objects
  context.output_hash["direct_digital_objects_ssm"] = accumulator
end

to_field "extent_ssm", extract_xpath("/ead/archdesc/did/physdesc/extent")
to_field "extent_teim", extract_xpath("/ead/archdesc/did/physdesc/extent")

to_field "date_range_sim", extract_xpath("/ead/archdesc/did/unitdate/@normal", to_text: false) do |_record, accumulator|
  range = Pulfalight::YearRange.new
  next range.years if accumulator.blank?

  ranges = accumulator.map(&:to_s)
  range << range.parse_ranges(ranges)
  accumulator.replace range.years
end

SEARCHABLE_NOTES_FIELDS.map do |selector|
  sanitizer = Rails::Html::SafeListSanitizer.new
  to_field "#{selector}_ssm", extract_xpath("/ead/archdesc/#{selector}/*[local-name()!='head']", to_text: false) do |_record, accumulator|
    accumulator.map! do |element|
      sanitizer.sanitize(element.to_html, tags: %w[extref]).gsub("extref", "a").strip
    end
  end
  to_field "#{selector}_heading_ssm", extract_xpath("/ead/archdesc/#{selector}/head")
  to_field "#{selector}_teim", extract_xpath("/ead/archdesc/#{selector}/*[local-name()!='head']")
  to_field "#{selector}_combined_tsm", extract_xpath("/ead/archdesc/#{selector}", to_text: false) do |_record, accumulator, context|
    content = accumulator.each_with_object({}) do |element, hsh|
      header = element.xpath("./head")[0].text || "Unknown"
      values = element.xpath("./p").map do |el|
        sanitizer.sanitize(el.to_html, tags: %w[extref]).gsub("extref", "a").strip
      end
      hsh[header] ||= []
      hsh[header].concat values
    end
    accumulator.clear
    context.output_hash["direct_content_warning_ssm"] = content["Content Warning"] if selector == "scopecontent"
    accumulator << ::JSON.dump(content)
  end
end

to_field "bioghist_ssm", extract_xpath("/ead/archdesc/bioghist", to_text: false) do |_record, accumulator|
  build_bioghist(accumulator)
end

DID_SEARCHABLE_NOTES_FIELDS.map do |selector|
  sanitizer = Rails::Html::SafeListSanitizer.new
  to_field "#{selector}_ssm", extract_xpath("/ead/archdesc/did/#{selector}", to_text: false) do |_record, accumulator|
    accumulator.map! do |element|
      sanitizer.sanitize(element.to_html, tags: %w[extref]).gsub("extref", "a").strip
    end
  end
end

NAME_ELEMENTS.map do |selector|
  to_field "names_coll_ssim", extract_xpath("/ead/archdesc/controlaccess/#{selector}")
  to_field "names_ssim", extract_xpath("//#{selector}[@role != 'processor'][@role != 'author']")
  to_field "names_ssim", extract_xpath("//#{selector}[not(@role)]")
  to_field "#{selector}_ssm", extract_xpath("//#{selector}")
end

to_field "corpname_sim", extract_xpath("//corpname")

to_field "physloc_sim" do |record, accumulator, _context|
  values = []
  record.xpath("/ead/archdesc/did/physloc").each do |physloc_element|
    code = Pulfalight::LocationCode.new(physloc_element.text).value
    if Pulfalight::LocationCode.registered?(code)
      location_code = Pulfalight::LocationCode.resolve(code)
      values << location_code.to_s
    end
  end

  accumulator.concat(values.uniq)
end

# to_field "physloc_ssm" do |_record, accumulator, context|
#   values = context.output_hash["physloc_sim"]
#   accumulator.concat(values)
# end

to_field "language_sim" do |record, accumulator, _context|
  elements = record.xpath("/ead/archdesc/did/langmaterial/language")
  values = []
  elements.each do |element|
    value = element.text
    # remove anything in parentheses
    # for example "Greek, Modern (1453-)" becomes "Greek, Modern"
    value = value.gsub(/\(.*?\)/, "").strip

    values << value
  end

  accumulator.concat(values)
end
to_field "language_ssm" do |_record, accumulator, context|
  values = context.output_hash["language_sim"]
  accumulator.concat(values) if values.present?
end

to_field "descrules_ssm", extract_xpath("/ead/eadheader/profiledesc/descrules")

to_field "prefercite_ssm" do |_record, accumulator, context|
  titles = context.output_hash["title_ssm"]
  title = titles.first
  output = "#{title}; "
  citation = CitationResolverService.resolve(repository_id: settings["repository"])
  if citation
    output += citation
    output += ", Princeton University Library"

    accumulator << output unless output.empty?
  end
end

to_field "prefercite_teim" do |_record, accumulator, context|
  accumulator.concat Array.wrap(context.output_hash["prefercite_ssm"])
end

to_field "collection_notes_ssm" do |record, accumulator, _context|
  child_nodes = record.xpath('/ead/archdesc/*[name() != "controlaccess"][name() != "dsc"]')
  child_text_nodes = child_nodes.select { |c| c.is_a?(Nokogiri::XML::Text) }
  accumulator.concat(child_text_nodes)

  child_elements = child_nodes.select { |c| c.is_a?(Nokogiri::XML::Element) }
  parse_nested_text = lambda do |node|
    text_nodes = []
    children = if node.name == "did"
                 node.xpath("./abstract").select { |c| c.class == Nokogiri::XML::Element }
               elsif node.name == "descgrp" && node["id"] == "dacs7"
                 node.xpath("./processinfo")
               else
                 node.children.select { |c| c.class == Nokogiri::XML::Element }
               end
    children.each do |c|
      text_nodes << [c.text.lstrip, "\n"].join
      text_nodes.concat(parse_nested_text.call(c)) unless node.name == "descgrp" && node["id"] == "dacs7"
    end
    text_nodes
  end

  text_node_ancestors = child_elements.flat_map { |c| parse_nested_text.call(c) }
  text_node_ancestors = text_node_ancestors.map { |t| t.gsub(/\s{2,}/, " ") }.uniq
  text_node_ancestors = text_node_ancestors.map { |t| t.gsub(/\s{1,}$/, "") }.uniq
  accumulator.concat(text_node_ancestors)
end

# For collection description tab.
to_field "sponsor_ssm", extract_xpath("/ead/eadheader/filedesc/titlestmt/sponsor")
to_field "collection_description_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash["scopecontent_ssm"] || [])
end
to_field "collection_bioghist_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash["bioghist_ssm"] || [])
end

# For find-more tab
to_field "subject_terms_ssim" do |record, accumulator|
  values = record.xpath('/ead/archdesc/controlaccess/subject[not(@source="local")]').map(&:text)
  occupations = record.xpath("/ead/archdesc/controlaccess/occupation").map(&:text)
  values = (values + occupations).map(&:strip)
  values = ChangeTheSubject.fix(subject_terms: values, separators: [" -- ", "--"]).sort

  accumulator.concat(values)
end

# For search only
to_field "archaic_subject_terms_ssim" do |record, accumulator, context|
  values = record.xpath('/ead/archdesc/controlaccess/subject[not(@source="local")]').map(&:text)
  values = values.map(&:strip)
  processed_values = context.output_hash.fetch("subject_terms_ssim", [])

  # Return array of original archaic values
  accumulator.concat(values - processed_values)
end

# For find-more tab
to_field "topics_ssim" do |record, accumulator|
  values = record.xpath('/ead/archdesc/controlaccess/subject[@source="local"]').map(&:text)
  accumulator << values.sort
end

# For find-more tab
to_field "genreform_ssim" do |record, accumulator|
  values = record.xpath("/ead/archdesc/controlaccess/genreform").map(&:text)
  accumulator << values.sort
end

to_field "access_ssi" do |record, accumulator, _context|
  value = record.xpath("./ead/archdesc/accessrestrict")&.first&.attributes&.fetch("rights-restriction", nil)&.value&.downcase
  value ||= "open"
  accumulator << value
end

to_field "components" do |record, accumulator, context|
  xpath = if record.is_a?(Nokogiri::XML::Document)
            "/ead/archdesc/dsc/c[@level != 'otherlevel']"
          else
            "./c[@level != 'otherlevel']"
          end
  child_components = record.xpath(xpath, Pulfalight::Ead2Indexing::NokogiriXpathExtensions.new)
  child_components.each do |child_component|
    component_indexer.settings do
      provide :parent, context
      provide :root, context
      provide :repository, context.settings[:repository]
    end
    output = component_indexer.map_record(child_component)
    accumulator << output
  end
end

# Configure the settings after the Document is indexed
configure_after
