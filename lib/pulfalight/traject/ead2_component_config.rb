# frozen_string_literal: true

require "logger"
require "traject"
require "traject/nokogiri_reader"
require "traject_plus"
require "traject_plus/macros"
require "arclight/missing_id_strategy"
require Rails.root.join("lib", "pulfalight", "traject", "ead2_indexing")

# rubocop:enable Style/MixinUsage

# =============================
# Each component child document
# <c> <c01> <c12>
# =============================

# Module for providing recursion over components

extend TrajectPlus::Macros

to_field "ref_ssi" do |record, accumulator, context|
  accumulator << if record.attribute("id").blank?
                   strategy = Arclight::MissingIdStrategy.selected
                   hexdigest = strategy.new(record).to_hexdigest
                   parent_id = context.clipboard[:parent].output_hash["id"].first
                   logger.warn("MISSING ID WARNING") do
                     [
                       "A component in #{parent_id} did not have an ID so one was minted using the #{strategy} strategy.",
                       "The ID of this document will be #{parent_id}#{hexdigest}."
                     ]
                   end
                   record["id"] = hexdigest
                   hexdigest
                 else
                   record.attribute("id")&.value&.strip&.gsub(".", "-")
                 end
end
to_field "ref_ssm" do |_record, accumulator, context|
  accumulator.concat context.output_hash["ref_ssi"]
end

to_field "id" do |_record, accumulator, context|
  accumulator.concat context.output_hash["ref_ssi"]
end

to_field "ead_ssi" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  ead_ids = parent.output_hash["ead_ssi"]
  accumulator << ead_ids.first unless ead_ids.blank?
end

to_field "title_filing_si", extract_xpath("./did/unittitle"), first_only
to_field "title_ssm", extract_xpath("./did/unittitle")
to_field "title_teim", extract_xpath("./did/unittitle")

to_field "unitdate_bulk_ssim", extract_xpath('./did/unitdate[@type="bulk"]')
to_field "unitdate_inclusive_ssm", extract_xpath('./did/unitdate[@type="inclusive"]')
to_field "unitdate_other_ssim", extract_xpath("./did/unitdate[not(@type)]")

to_field "normalized_title_ssm" do |_record, accumulator, context|
  dates = Pulfalight::NormalizedDate.new(
    context.output_hash["unitdate_inclusive_ssm"],
    context.output_hash["unitdate_bulk_ssim"],
    context.output_hash["unitdate_other_ssim"]
  ).to_s
  title = context.output_hash["title_ssm"]&.first
  accumulator << Pulfalight::NormalizedTitle.new(title, dates).to_s
end

to_field "normalized_date_ssm" do |_record, accumulator, context|
  accumulator << Pulfalight::NormalizedDate.new(
    context.output_hash["unitdate_inclusive_ssm"],
    context.output_hash["unitdate_bulk_ssim"],
    context.output_hash["unitdate_other_ssim"]
  ).to_s
end

to_field "component_level_isim" do |record, accumulator|
  accumulator << 1 + Pulfalight::Ead2Indexing::NokogiriXpathExtensions.new.is_component(record.ancestors).count
end

to_field "parent_ssm" do |record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  ids = parent.output_hash["id"]
  unless ids.blank?
    accumulator << ids.first
    accumulator.concat Pulfalight::Ead2Indexing::NokogiriXpathExtensions.new.is_component(record.ancestors).reverse.map { |n| n.attribute("id")&.value&.strip&.gsub(".", "-") }
  end
end

to_field "parent_ssi" do |_record, accumulator, context|
  accumulator << context.output_hash["parent_ssm"].last unless context.output_hash["parent_ssm"].blank?
end

to_field "parent_unittitles_ssm" do |_rec, accumulator, context|
  # top level document
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  accumulator.concat parent.output_hash["normalized_title_ssm"] unless parent.output_hash["normalized_title_ssm"].blank?
  parent_ssm = context.output_hash["parent_ssm"]
  components = parent.output_hash["components"]

  # other components
  if parent_ssm && components
    ancestors = parent_ssm.drop(1).map { |x| [x] }
    accumulator.concat components.select { |c| ancestors.include? c["ref_ssi"] }.flat_map { |c| c["normalized_title_ssm"] }
  end
end

to_field "parent_unittitles_teim" do |_record, accumulator, context|
  accumulator.concat context.output_hash["parent_unittitles_ssm"] unless context.output_hash["parent_unittitles_ssm"].blank?
end

to_field "parent_levels_ssm" do |_record, accumulator, context|
  ## Top level document
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  accumulator.concat parent.output_hash["level_ssm"]
  ## Other components
  context.output_hash["parent_ssm"]&.drop(1)&.each do |id|
    accumulator.concat Array
      .wrap(parent.output_hash["components"])
      .select { |c| c["ref_ssi"] == [id] }.map { |c| c["level_ssm"] }.flatten
  end
end

to_field "unitid_ssm", extract_xpath("./did/unitid")
to_field "collection_unitid_ssm" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  accumulator.concat Array.wrap(parent.output_hash["unitid_ssm"])
end
to_field "repository_ssm" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  accumulator << parent.clipboard[:repository]
end
to_field "repository_sim" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  accumulator << parent.clipboard[:repository]
end
to_field "collection_ssm" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  normalized_title = parent.output_hash["normalized_title_ssm"]

  accumulator.concat normalized_title unless parent.nil? || normalized_title.nil?
end
to_field "collection_sim" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  normalized_title = parent.output_hash["normalized_title_ssm"]

  accumulator.concat normalized_title unless parent.nil? || normalized_title.nil?
end
to_field "collection_ssi" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  normalized_title = parent.output_hash["normalized_title_ssm"]

  accumulator.concat normalized_title unless parent.nil? || normalized_title.nil?
end

to_field "extent_ssm", extract_xpath("./did/physdesc/extent")
to_field "extent_teim", extract_xpath("./did/physdesc/extent")

to_field "creator_ssm", extract_xpath("./did/origination")
to_field "creator_ssim", extract_xpath("./did/origination")
to_field "creators_ssim", extract_xpath("./did/origination")
to_field "creator_sort" do |record, accumulator|
  accumulator << record.xpath("./did/origination").map(&:text).join(", ")
end
to_field "collection_creator_ssm" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  next unless parent

  accumulator.concat Array.wrap(parent.output_hash["creator_ssm"])
end
to_field "has_online_content_ssim", extract_xpath(".//dao") do |_record, accumulator|
  accumulator.replace([accumulator.any?])
end
to_field "child_component_count_isim" do |record, accumulator|
  accumulator << Pulfalight::Ead2Indexing::NokogiriXpathExtensions.new.is_component(record.children).count
end

to_field "ref_ssm" do |record, accumulator|
  accumulator << record.attribute("id")
end

to_field "level_ssm" do |record, accumulator|
  level = record.attribute("level")&.value
  other_level = record.attribute("otherlevel")&.value
  accumulator << Arclight::LevelLabel.new(level, other_level).to_s
end

to_field "level_sim" do |_record, accumulator, context|
  next unless context.output_hash["level_ssm"]

  accumulator.concat context.output_hash["level_ssm"]&.map(&:capitalize)
end

to_field "sort_ii" do |_record, accumulator, context|
  accumulator.replace([context.position])
end

# Get the <accessrestrict> from the closest ancestor that has one (includes top-level)
to_field "parent_access_restrict_ssm" do |record, accumulator|
  accumulator.concat Array
    .wrap(record.xpath('(./ancestor::*/accessrestrict)[last()]/*[local-name()!="head"]')
    .map(&:text))
end

# Get the <userestrict> from self OR the closest ancestor that has one (includes top-level)
to_field "parent_access_terms_ssm" do |record, accumulator|
  accumulator.concat Array
    .wrap(record.xpath('(./ancestor-or-self::*/userestrict)[last()]/*[local-name()!="head"]')
    .map(&:text))
end

to_field "digital_objects_ssm", extract_xpath(".//dao", to_text: false) do |_record, accumulator|
  accumulator.map! do |dao|
    label = dao.attributes["title"]&.value ||
            dao.xpath("daodesc/p")&.text
    href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
    role = (dao.attributes["role"] || dao.attributes["xlink:role"])&.value
    Arclight::DigitalObject.new(label: label, href: href, role: role).to_json
  end
end

to_field "direct_digital_objects_ssm", extract_xpath("./dao", to_text: false) do |_record, accumulator|
  accumulator.map! do |dao|
    label = dao.attributes["title"]&.value ||
            dao.xpath("daodesc/p")&.text
    href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
    Arclight::DigitalObject.new(label: label, href: href).to_json
  end
end

to_field "date_range_sim", extract_xpath("./did/unitdate/@normal", to_text: false) do |_record, accumulator|
  range = Pulfalight::YearRange.new
  next range.years if accumulator.blank?

  ranges = accumulator.map(&:to_s)
  range << range.parse_ranges(ranges)
  accumulator.replace range.years
end

Pulfalight::Ead2Indexing::NAME_ELEMENTS.map do |selector|
  to_field "names_ssim", extract_xpath("./controlaccess/#{selector}")
  to_field "#{selector}_ssm", extract_xpath(".//#{selector}")
end

to_field "geogname_sim", extract_xpath("./controlaccess/geogname")
to_field "geogname_ssm", extract_xpath("./controlaccess/geogname")
to_field "places_ssim", extract_xpath("./controlaccess/geogname")

to_field "access_subjects_ssim", extract_xpath("./controlaccess", to_text: false) do |_record, accumulator|
  accumulator.map! do |element|
    %w[subject function occupation genreform].map do |selector|
      element.xpath(".//#{selector}").map(&:text)
    end
  end.flatten!
end

to_field "access_subjects_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash.fetch("access_subjects_ssim", []))
end

to_field "acqinfo_ssim", extract_xpath('/ead/archdesc/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssim", extract_xpath('/ead/archdesc/descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssim", extract_xpath('./acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssim", extract_xpath('./descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash.fetch("acqinfo_ssim", []))
end

to_field "language_ssm", extract_xpath("./did/langmaterial")
to_field "containers_ssim" do |record, accumulator|
  record.xpath("./did/container").each do |node|
    accumulator << [node.attribute("type"), node.text].join(" ").strip
  end
end

Pulfalight::Ead2Indexing::SEARCHABLE_NOTES_FIELDS.map do |selector|
  to_field "#{selector}_ssm", extract_xpath("./#{selector}/*[local-name()!='head']")
  to_field "#{selector}_heading_ssm", extract_xpath("./#{selector}/head")
  to_field "#{selector}_teim", extract_xpath("./#{selector}/*[local-name()!='head']")
end
Pulfalight::Ead2Indexing::DID_SEARCHABLE_NOTES_FIELDS.map do |selector|
  to_field "#{selector}_ssm", extract_xpath("./did/#{selector}")
end
to_field "did_note_ssm", extract_xpath("./did/note")

to_field "prefercite_ssm" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  parent_ids = parent.output_hash["id"]
  parent_id = parent_ids.first
  parent_titles = parent.output_hash["title_ssm"]
  parent_title = parent_titles.first
  output = "#{parent_title}, #{parent_id}, "
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

to_field "collection_notes_ssm" do |_record, accumulator, context|
  parent = context.clipboard[:parent] || settings[:parent]
  accumulator.concat(parent.output_hash["collection_notes_ssm"])
end

to_field "components" do |record, accumulator, _context|
  child_components = record.xpath("./*[is_component(.)][@level != 'otherlevel']", NokogiriXpathExtensions.new)
  child_components.each do |child_component|
    root_context = settings[:parent]
    component_indexer = build_component_indexer(root_context)
    output = component_indexer.map_record(child_component)
    accumulator << output
  end
end
