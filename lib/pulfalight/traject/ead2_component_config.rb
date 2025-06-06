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

# rubocop:disable Style/MixinUsage
extend TrajectPlus::Macros
# rubocop:enable Style/MixinUsage

to_field "ref_ssi" do |record, accumulator, _context|
  accumulator << if record.attribute("id").blank?
                   strategy = Arclight::MissingIdStrategy.selected
                   hexdigest = strategy.new(record).to_hexdigest
                   parent_id = settings[:parent].output_hash["id"].first
                   logger.warn("MISSING ID WARNING") do
                     [
                       "A component in #{parent_id} did not have an ID so one was minted using the #{strategy} strategy.",
                       "The ID of this document will be #{parent_id}#{hexdigest}."
                     ]
                   end
                   record["id"] = hexdigest
                   hexdigest
                 else
                   record.attribute("id")&.value&.strip&.gsub("aspace_", "")&.split(" ")&.first
                 end
end
to_field "ref_ssm" do |_record, accumulator, context|
  accumulator.concat context.output_hash["ref_ssi"]
end

to_field "id" do |_record, accumulator, context|
  accumulator.concat context.output_hash["ref_ssi"].map { |x| x.tr(".", "-") }
end

to_field "hashed_id_ssi" do |_record, accumulator, context|
  accumulator << Digest::MD5.hexdigest(context.output_hash["id"].first)
end

to_field "ead_ssi" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  next unless parent

  ead_ids = parent.output_hash["ead_ssi"]
  accumulator << ead_ids.first if ead_ids.present?
end

to_field "title_filing_si", extract_xpath("./did/unittitle"), first_only
to_field "title_ssm", extract_xpath("./did/unittitle")
to_field "title_teim", extract_xpath("./did/unittitle")
to_field "subtitle_ssm", extract_xpath("./did/unittitle")
to_field "subtitle_teim", extract_xpath("./did/unittitle")

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

to_field "parent_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  next unless parent

  ids = parent.output_hash["id"]
  if ids.present?
    accumulator.concat parent.output_hash["parent_ssm"] if parent.output_hash["parent_ssm"]
    accumulator << ids.first
  end
end

to_field "collection_title_tesim" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent

  accumulator.concat Array.wrap(parent.output_hash["collection_title_tesim"])
end

to_field "parent_ssi" do |_record, accumulator, context|
  accumulator << context.output_hash["parent_ssm"].last if context.output_hash["parent_ssm"].present?
end

to_field "parent_unittitles_ssm" do |_rec, accumulator, _context|
  # top level document
  parent = settings[:parent] || settings[:root]
  next unless parent
  accumulator.concat parent.output_hash["parent_unittitles_ssm"] if parent.output_hash["parent_unittitles_ssm"]
  accumulator.concat parent.output_hash["normalized_title_ssm"] if parent.output_hash["normalized_title_ssm"].present?
end

to_field "parent_unnormalized_unittitles_ssm" do |_rec, accumulator, _context|
  # top level document
  parent = settings[:parent] || settings[:root]
  next unless parent
  accumulator.concat parent.output_hash["parent_unnormalized_unittitles_ssm"] if parent.output_hash["parent_unnormalized_unittitles_ssm"]
  accumulator.concat parent.output_hash["title_ssm"] if parent.output_hash["title_ssm"].present?
end

to_field "parent_unittitles_teim" do |_record, accumulator, context|
  accumulator.concat context.output_hash["parent_unittitles_ssm"] if context.output_hash["parent_unittitles_ssm"].present?
end

to_field "parent_unittitles_ssim" do |_record, accumulator, context|
  accumulator.concat context.output_hash["parent_unittitles_ssm"] if context.output_hash["parent_unittitles_ssm"].present?
end

to_field "parent_levels_ssm" do |_record, accumulator, context|
  ## Top level document
  parent = settings[:parent] || settings[:root]
  next unless parent

  accumulator.concat parent.output_hash["level_ssm"]
  ## Other components
  context.output_hash["parent_ssm"]&.drop(1)&.each do |id|
    accumulator.concat Array
      .wrap(parent.output_hash["components"])
      .select { |c| c["ref_ssi"] == [id] }.map { |c| c["level_ssm"] }.flatten
  end
end

to_field "unitid_ssm" do |record, accumulator, _context|
  accumulator.concat record.xpath("./did/unitid[not(@type='aspace_uri')]").map(&:text).map { |x| x.gsub("aspace_", "") }
end
to_field "system_identifier_ssm" do |record, accumulator, _context|
  accumulator.concat record.xpath("./did/unitid[@type='aspace_uri']").map(&:text)
end
to_field "collection_unitid_ssm" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent

  accumulator.concat Array.wrap(parent.output_hash["unitid_ssm"])
end
to_field "repository_ssm" do |_record, accumulator, _context|
  accumulator.concat settings[:root].output_hash["repository_ssm"]
end
to_field "repository_sim" do |_record, accumulator, _context|
  accumulator.concat settings[:root].output_hash["repository_sim"]
end

to_field "repository_code_ssm" do |_record, accumulator, context|
  accumulator << context.settings[:repository]
end

to_field "collection_ssm" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent

  normalized_title = parent.output_hash["normalized_title_ssm"]

  accumulator.concat normalized_title unless parent.nil? || normalized_title.nil?
end
to_field "collection_sim" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent

  normalized_title = parent.output_hash["normalized_title_ssm"]

  accumulator.concat normalized_title unless parent.nil? || normalized_title.nil?
end
to_field "collection_ssi" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent

  normalized_title = parent.output_hash["normalized_title_ssm"]

  accumulator.concat normalized_title unless parent.nil? || normalized_title.nil?
end

to_field "extent_ssm", extract_xpath("./did/physdesc/extent")
to_field "extent_teim", extract_xpath("./did/physdesc/extent")

to_field "dimensions_ssm", extract_xpath("./did/physdesc/dimensions")
to_field "dimensions_teim", extract_xpath("./did/physdesc/dimensions")

to_field "physfacet_ssm", extract_xpath("./did/physdesc/physfacet")
to_field "physfacet_teim", extract_xpath("./did/physdesc/physfacet")

to_field "collection_physloc_ssm" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent
  collection_physloc = parent.output_hash["physloc_ssm"]
  accumulator.concat(collection_physloc) if collection_physloc
end

to_field "physloc_code_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  next unless parent

  physloc_code = parent.output_hash["physloc_code_ssm"]
  accumulator.concat(physloc_code) if physloc_code
end

to_field "location_code_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  next unless parent

  physloc_code = parent.output_hash["location_code_ssm"]
  accumulator.concat(physloc_code) if physloc_code
end

to_field "location_note_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  next unless parent

  physloc_code = parent.output_hash["location_note_ssm"]
  accumulator.concat(physloc_code) if physloc_code
end

to_field "volume_ssm" do |record, accumulator|
  record.xpath("./did/physdesc[@altrender='whole']/extent[@altrender='materialtype spaceoccupied']").each do |extent_element|
    accumulator << extent_element.text if extent_element.text.downcase.include?("vol")
  end
end

to_field "physdesc_number_ssm" do |record, accumulator|
  record.xpath("./did/physdesc").each do |extent_element|
    accumulator << extent_element.text if /^\d+$/.match?(extent_element.text)
  end
end

to_field "creator_ssm", extract_xpath("./did/origination")
to_field "creator_ssim", extract_xpath("./did/origination")
to_field "creator_tesim", extract_xpath("./did/origination")
to_field "creators_ssim", extract_xpath("./did/origination")
to_field "creator_sort" do |record, accumulator|
  accumulator << record.xpath("./did/origination").map(&:text).join(", ")
end
to_field "collection_creator_ssm" do |_record, accumulator, _context|
  parent = settings[:root]
  next unless parent

  accumulator.concat Array.wrap(parent.output_hash["creator_ssm"])
end
to_field "has_online_content_ssim", extract_xpath(".//dao", to_text: false) do |_record, accumulator|
  accumulator.replace([accumulator.any? { |dao| index_dao?(dao) }])
end
to_field "has_direct_online_content_ssim", extract_xpath("./did/dao", to_text: false) do |_record, accumulator|
  accumulator.replace([accumulator.any? { |dao| index_dao?(dao) }])
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

to_field "container_location_codes_ssim" do |record, accumulator, context|
  record.xpath("./did/container").each do |container_element|
    container_location_code = Pulfalight::LocationCode.new(container_element.attributes["altrender"].to_s).value
    accumulator << container_location_code if container_location_code.present?
  end
  if context.output_hash["level_ssm"] == ["Text"] && accumulator.blank?
    # Text records have no container information, but can be requested. Copy the
    # container info from the parent.
    parent = settings[:parent]
    accumulator.replace(parent.output_hash["container_location_codes_ssim"] || [])
  end
end

to_field "container_information_ssm" do |record, accumulator, context|
  record.xpath("./did/container").each do |container_element|
    container_location_code = Pulfalight::LocationCode.new(container_element.attributes["altrender"].to_s).value
    container_profile = container_element.attributes["encodinganalog"].to_s
    type = container_element.attributes["type"].to_s
    next if container_location_code.blank? && type != "folder"
    barcode_label = container_element.attributes["label"].to_s
    barcode_match = barcode_label.match(/\[(\d+?)\]/)
    barcode = barcode_match[1] if barcode_match
    text = [container_element.attribute("type"), container_element.text].join(" ").strip
    note = container_element.attribute("note")
    accumulator << {
      id: container_element.attributes["id"].to_s.gsub("aspace_", ""),
      location_code: container_location_code,
      profile: container_profile,
      barcode: barcode,
      label: text,
      note: note.to_s,
      parent: container_element.attribute("parent").to_s.gsub("aspace_", ""),
      type: type
    }.to_json
  end
  if context.output_hash["level_ssm"] == ["Text"] && accumulator.blank?
    # Text records have no container information, but can be requested. Copy the
    # container info from the parent.
    parent = settings[:parent]
    accumulator.replace(parent.output_hash["container_information_ssm"] || [])
  end
end

to_field "containers_ssim" do |record, accumulator, context|
  if context.output_hash["level_ssm"] == ["Text"]
    # Text records have no container information, but can be requested. Copy the
    # container info from the parent.
    parent = settings[:parent]
    accumulator.replace(parent.output_hash["containers_ssim"] || [])
  else
    record.xpath("./did/container").each do |node|
      accumulator << [node.attribute("type"), node.text].join(" ").strip
    end
  end
end

to_field "barcodes_ssim" do |record, accumulator, context|
  record.xpath("./did/container[@label]").each do |node|
    label = node.attr("label")
    barcode_match = label.match(/\[(\d+?)\]/)
    accumulator << barcode_match[1] if barcode_match
  end
  if context.output_hash["level_ssm"] == ["Text"] && accumulator.blank?
    # Text records have no container information, but can be requested. Copy the
    # container info from the parent.
    parent = settings[:parent]
    accumulator.replace(parent.output_hash["barcodes_ssim"] || [])
  end
end

# Component level summary storage a.k.a. "magic physloc"
to_field "summary_storage_note_ssm" do |record, accumulator, _context|
  locations = {}

  record.xpath(".//container[not(@parent)]").each do |container|
    # make the data look like this:
    # "hsvm" => {"box" => ["1", "323", "2", "3", "4", "5", "6"], "volume" => ["42", "43", "44", "45"]}
    container_type = container["type"]
    location_code = Pulfalight::LocationCode.new(container["altrender"].to_s).value
    location_hash = locations.fetch(location_code, {})
    location_hash[container_type] = location_hash.fetch(container_type, [])
    location_hash[container_type] << container.text
    locations[location_code] = location_hash
  end

  json = Pulfalight::NormalizedBoxLocations.new(locations).to_h.to_json
  accumulator << json
end

# TODO: Add for otherlevel=text
to_field "physloc_sim" do |record, accumulator, context|
  values = []
  container_elements = record.xpath("./did/container")
  container_elements.each do |container_element|
    next unless container_element["type"]

    container_type = container_element["type"].capitalize
    container_value = container_element.text
    container_note = container_element["note"]
    values << "#{container_type} #{container_value} #{container_note}".strip
  end
  values = Array.wrap(values.join(", "))

  if values.empty?
    parent = settings[:parent] || settings[:root]
    values = parent.output_hash["physloc_sim"]
  end

  accumulator.concat(values)
  if context.output_hash["level_ssm"] == ["Text"] && accumulator.select(&:present?).blank?
    # Text records have no container information, but can be requested. Copy the
    # container info from the parent.
    parent = settings[:parent]
    accumulator.replace(parent.output_hash["physloc_sim"] || [])
  end
end
to_field "physloc_ssm" do |_record, accumulator, context|
  values = context.output_hash["physloc_sim"]
  accumulator.concat(values)
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
    next unless index_dao?(dao)
    label = dao.attributes["title"]&.value ||
            dao.xpath("daodesc/p")&.text
    href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
    role = (dao.attributes["role"] || dao.attributes["xlink:role"])&.value
    Arclight::DigitalObject.new(label: label, href: href, role: role).to_json
  end.compact
end

to_field "direct_digital_objects_ssm", extract_xpath("./did/dao", to_text: false) do |_record, accumulator|
  accumulator.map! do |dao|
    next unless index_dao?(dao)
    label = dao.attributes["title"]&.value ||
            dao.xpath("daodesc/p")&.text
    href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
    role = (dao.attributes["role"] || dao.attributes["xlink:role"])&.value
    Arclight::DigitalObject.new(label: label, href: href, role: role).to_json
  end.compact
end

to_field "date_range_sim", extract_xpath("./did/unitdate/@normal", to_text: false) do |_record, accumulator|
  range = Pulfalight::YearRange.new
  next range.years if accumulator.blank?

  ranges = accumulator.map(&:to_s)
  range << range.parse_ranges(ranges)
  accumulator.replace range.years
end

Pulfalight::Ead2Indexing::NAME_ELEMENTS.map do |selector|
  to_field "names_coll_ssim", extract_xpath("/ead/archdesc/controlaccess/#{selector}")
  to_field "names_ssim", extract_xpath("./controlaccess/#{selector}[@role != 'processor'][@role != 'author']")
  to_field "names_ssim", extract_xpath("./controlaccess/#{selector}[not(@role)]")
  to_field "#{selector}_ssm", extract_xpath(".//#{selector}")
end

to_field "geogname_sim", extract_xpath("./controlaccess/geogname")
to_field "geogname_ssm", extract_xpath("./controlaccess/geogname")
to_field "places_ssim", extract_xpath("./controlaccess/geogname")

to_field "access_subjects_ssim" do |record, accumulator|
  values = record.xpath("./controlaccess")
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
  values = record.xpath("./controlaccess")
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
  accumulator.concat(context.output_hash.fetch("access_subjects_ssim", []))
end

to_field "acqinfo_ssim", extract_xpath('./acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssim", extract_xpath('./descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_teim", extract_xpath('./acqinfo/*[local-name()!="head"]')
to_field "acqinfo_teim", extract_xpath('./descgrp/acqinfo/*[local-name()!="head"]')
to_field "acqinfo_ssm" do |_record, accumulator, context|
  accumulator.concat(context.output_hash.fetch("acqinfo_ssim", []))
end

to_field "location_info_tesim" do |_record, accumulator, context|
  values = context.output_hash["physloc_sim"]
  collection_unitid = Array.wrap(context.output_hash["collection_unitid_ssm"]).first
  values = values.map do |value|
    "#{collection_unitid} #{value}"
  end
  accumulator.concat(values)
end

to_field "language_sim" do |record, accumulator, _context|
  elements = record.xpath("./did/langmaterial/language")
  values = []
  elements.each do |element|
    value = element.text
    segments = value.split

    filtered = segments.reject { |e| e =~ /^[[:punct:]]/ }
    value = filtered.join(" ")

    values << value
  end

  accumulator.concat(values)
end

to_field "language_ssm" do |_record, accumulator, context|
  values = context.output_hash["language_sim"]
  accumulator.concat(values) if values
end

# Inherit from parent if empty.
to_field "language_ssm" do |_record, accumulator, context|
  if context.output_hash["language_ssm"].blank?
    parent = settings[:parent] || settings[:root]
    parent_languages = parent.output_hash["language_ssm"] || []

    accumulator.concat(parent_languages)
  end
end

NON_INHERITABLE_NOTES = %w[scopecontent processinfo].freeze
Pulfalight::Ead2Indexing::SEARCHABLE_NOTES_FIELDS.map do |selector|
  sanitizer = Rails::Html::SafeListSanitizer.new
  to_field "#{selector}_ssm", extract_xpath("./#{selector}/*[local-name()!='head']", to_text: false) do |_record, accumulator|
    accumulator.map! do |element|
      CGI.unescapeHTML(sanitizer.sanitize(element.to_html, tags: %w[extref]).gsub("extref", "a").strip)
    end
    # Inherit notes from parent if blank.
    if accumulator.blank? && NON_INHERITABLE_NOTES.exclude?(selector)
      parent = settings[:parent] || settings[:root]
      accumulator.concat(Array.wrap(parent.output_hash["#{selector}_ssm"]))
    end
  end

  to_field "#{selector}_heading_ssm", extract_xpath("./#{selector}/head")
  to_field "#{selector}_teim", extract_xpath("./#{selector}/*[local-name()!='head']")

  to_field "#{selector}_combined_tsm", extract_xpath("./#{selector}", to_text: false) do |_record, accumulator, context|
    content = accumulator.each_with_object({}) do |element, hsh|
      header = element.xpath("./head")[0].text || "Unknown"
      values = element.xpath("./p").map do |el|
        CGI.unescapeHTML(sanitizer.sanitize(el.to_html, tags: %w[extref]).gsub("extref", "a").strip)
      end
      hsh[header] ||= []
      hsh[header].concat values
    end
    accumulator.clear

    # For scope & contents, inherit ONLY content warning.
    if selector == "scopecontent"
      context.output_hash["direct_content_warning_ssm"] = content["Content Warning"]
      parent = settings[:parent] || settings[:root]
      parent_values = Array.wrap(parent.output_hash["#{selector}_combined_tsm"].clone)
      # parent values is an array containing one stringified JSON hash
      # with all the parent values
      # extract just the content warning, keep it as a hash
      parent_warning = parent_values.map do |parent_value|
        ::JSON.parse(parent_value).slice("Content Warning")
      end.reduce({}, :merge)

      new_content = content.reverse_merge(parent_warning)
      if new_content.present?
        accumulator.append(::JSON.dump(new_content))
        scope_values = new_content.values.flatten
        context.output_hash["scopecontent_ssm"] = scope_values
      end

    # For all other notes, inherit from parent if it's blank.
    elsif accumulator.blank? && NON_INHERITABLE_NOTES.exclude?(selector)
      accumulator << ::JSON.dump(content) if content.present?
      parent = settings[:parent] || settings[:root]
      parent_values = Array.wrap(parent.output_hash["#{selector}_combined_tsm"])
      accumulator.concat(parent_values)
    end
  end
end

(Pulfalight::Ead2Indexing::DID_SEARCHABLE_NOTES_FIELDS - ["physloc"]).map do |selector|
  to_field "#{selector}_ssm", extract_xpath("./did/#{selector}")
end
to_field "did_note_ssm", extract_xpath("./did/note")

to_field "prefercite_ssm" do |_record, accumulator, context|
  parent = settings[:root]
  parent_ids = parent.output_hash["id"]
  parent_id = parent_ids.first
  parent_titles = parent.output_hash["title_ssm"]
  parent_title = parent_titles.first
  component_title = context.output_hash["title_ssm"]&.first
  output = [component_title, "#{parent_title}, #{parent_id}, "].compact.join("; ")
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

to_field "collection_notes_ssm" do |_record, accumulator, _context|
  parent = settings[:root]
  accumulator.concat(parent.output_hash["collection_notes_ssm"] || [])
end

# For collection description tab
to_field "collection_description_ssm" do |_record, accumulator, _context|
  parent = settings[:root]
  value = parent.output_hash["collection_description_ssm"] || []
  accumulator.concat(value)
end

# For collection history tab
to_field "processinfo_processing_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  value = parent.output_hash["processinfo_processing_ssm"] || []
  accumulator.concat(value)
end
to_field "processinfo_conservation_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  value = parent.output_hash["processinfo_conservation_ssm"] || []
  accumulator.concat(value)
end

# For collection history tab
to_field "sponsor_ssm" do |_record, accumulator, _context|
  parent = settings[:parent] || settings[:root]
  value = parent.output_hash["sponsor_ssm"] || []
  accumulator.concat(value)
end

to_field "access_ssi" do |record, accumulator, _context|
  value = record.xpath("./accessrestrict")&.first&.attributes&.fetch("rights-restriction", nil)&.value&.downcase
  parent = settings[:parent]
  value ||= parent.output_hash["access_ssi"]&.first
  value ||= "open"
  accumulator << value
end

# For find-more tab
to_field "subject_terms_ssim" do |record, accumulator|
  values = record.xpath('./controlaccess/subject[not(@source="local")]').map(&:text)
  values = values.map(&:strip)
  values = ChangeTheSubject.fix(subject_terms: values, separators: [" -- ", "--"]).sort
  accumulator.concat(values)
end

# For search only
to_field "archaic_subject_terms_ssim" do |record, accumulator, context|
  values = record.xpath('./controlaccess/subject[not(@source="local")]').map(&:text)
  values = values.map(&:strip)
  processed_values = context.output_hash.fetch("subject_terms_ssim", [])

  # Return array of original archaic values
  accumulator.concat(values - processed_values)
end

# For find-more tab
to_field "topics_ssim", extract_xpath('./controlaccess/subject[@source="local"]')

# For find-more tab
to_field "genreform_ssim", extract_xpath("./controlaccess/genreform")

to_field "bioghist_ssm", extract_xpath("./bioghist", to_text: false) do |_record, accumulator|
  build_bioghist(accumulator)
end

to_field "components" do |record, accumulator, context|
  child_components = record.xpath("./*[is_component(.)]", NokogiriXpathExtensions.new)
  child_components.each do |child_component|
    component_indexer.settings do
      provide :parent, context
      provide :root, context.settings[:root]
      provide :repository, context.settings[:repository]
    end
    component_indexer.settings[:parent] = context
    output = component_indexer.map_record(child_component)
    accumulator << output
  end
end
