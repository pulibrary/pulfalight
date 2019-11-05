defmodule MegaParser do
  import SweetXml

  @moduledoc """
  Documentation for MegaParser.
  """

  def parse(file) when is_binary(file) do
    parsed_file = file
                  |> SweetXml.parse
    parent_record = parent_record(parsed_file)
    components = components(parsed_file, parent_record)
    parent_record
    |> Map.put(:components, components)
  end

  require IEx
  defp components(parsed_file, parent_record) do
    IEx.pry
    parsed_file
    |> SweetXml.xpath(
      ~x"//c"l,
      ref_ssi: ~x"./@id"s,
      has_online_content_ssim: ~x".//dao"le |> transform_by(fn(x) -> [length(x) > 0] end),
      geogname_sim: ~x"./controlaccess/geogname/text()"ls,
      containers_ssim: ~x"./did/container"le |> transform_by(&container_string/1),
      level_ssm: ~x"."e |> transform_by(&extract_level/1),
      component_level_isim: ~x"ancestor-or-self::*"l |> transform_by(&length/1)
    )
    |> insert_sort
    |> Enum.map(&process_component(&1,parent_record))
  end

  defp count_ancestors(elements) do
    [length(elements)]
  end

  defp insert_sort(components) when is_list(components) do
    components
    |> Enum.map(&insert_sort(&1, components))
  end
  defp insert_sort(component, components) do
    component
    |> Map.put(:sort_ii, Enum.find_index(components, fn(x) -> x == component end))
  end

  defp container_string(containers) when is_list(containers) do
    containers
    |> Enum.map(&container_string/1)
  end
  require IEx
  defp container_string(%{type: type, text: text}) do
    "#{type} #{text}" |> String.trim
  end
  defp container_string(container) do
    type = container |> SweetXml.xpath(~x"./@type"s)
    text = container |> SweetXml.xpath(~x"./text()"s)
    %{
      type: type,
      text: text
    }
    |> container_string
  end

  defp process_component(component, parent_record) do
    component
    |> Map.put(:id, "#{parent_record.id}#{component.ref_ssi}")
    |> Map.put(:ead_ssi, parent_record.ead_ssi)
    |> Map.put(:geogname_ssm, component.geogname_sim)
    |> Map.put(:collection_unitid_ssm, parent_record.unitid_ssm)
    |> Map.put(:level_sim, component.level_ssm)
  end


  defp parent_record(parsed_file) do
    parsed_file
    |> SweetXml.xpath(
      ~x"/ead[last()]",
      id: ~x"./eadheader/eadid/text()"s |> transform_by(fn(x) -> x |> String.trim |> String.replace(".","-") end),
      title_filing_si: ~x"./eadheader/filedesc/titlestmt/titleproper[@type='filing']/text()"s,
      title_ssm: ~x"./archdesc/did/unittitle/text()"ls |> transform_by(fn(x) -> x |> Enum.map(&String.trim/1) end),
      ead_ssi: ~x"./eadheader/eadid/text()"s |> transform_by(&String.trim/1),
      unitdate_ssm: ~x"./archdesc/did/unitdate/text()"ls,
      unitdate_bulk_ssim: ~x"./archdesc/did/unitdate[@type='bulk']/text()"ls,
      unitdate_inclusive_ssm: ~x"./archdesc/did/unitdate[@type='inclusive']/text()"ls,
      unitdate_other_ssim: ~x"./archdesc/did/unitdate[not(@type)]"ls,
      level_sim: ~x"./archdesc"e |> transform_by(&extract_level/1),
      unitid_ssm: ~x"./archdesc/did/unitid/text()"ls,
      collection_unitid_ssm: ~x"./archdesc/did/unitid/text()"ls,
      geogname_ssm: ~x"./archdesc/controlaccess/geogname/text()"ls,
      creator_ssm: ~x"./archdesc/did/origination/*/text()"ls,
      creator_persname_ssm: ~x"./archdesc/did/origination/persname/text()"ls,
      creator_corpname_ssm: ~x"./archdesc/did/origination/corpname/text()"ls,
      creator_famname_ssm: ~x"./archdesc/did/origination/famname/text()"ls,
      persname_sim: ~x"//persname/text()"ls,
      access_terms_ssm: ~x"./archdesc/userestrict/*[local-name()!='head']/text()"ls,
      acqinfo_ssim: ~x"./archdesc/descgrp/acqinfo/*[local-name()!='head']/descendant-or-self::text()"s,
      access_subjects_ssim: ~x"./archdesc/controlaccess/*[self::subject or self::function or self::occupation or self::genreform]/text()"ls,
      extent_ssm: ~x"./archdesc/did/physdesc/extent/text()"ls,
      genreform_sim: ~x"./archdesc/controlaccess/genreform/text()"ls,
    )
    |> process_parent_record

  end

  defp process_parent_record(record) do
    record
    |> Map.put(:level_ssm, "collection")
    |> Map.put(:title_teim, record.title_ssm)
    |> Map.put(:unitid_teim, record.unitid_ssm)
    |> Map.put(:geogname_sim, record.geogname_ssm)
    |> Map.put(:places_sim, record.geogname_ssm)
    |> Map.put(:places_ssim, record.geogname_ssm)
    |> Map.put(:places_ssm, record.geogname_ssm)
    |> Map.put(:creator_sim, record.creator_ssm)
    |> Map.put(:creator_ssim, record.creator_ssm)
    |> Map.put(:creator_sort, Enum.join(record.creator_ssm, ", "))
    |> Map.put(:creator_persname_ssim, record.creator_persname_ssm)
    |> Map.put(:creator_corpname_ssim, record.creator_corpname_ssm)
    |> Map.put(:creator_corpname_sim, record.creator_corpname_ssm)
    |> Map.put(:creator_famname_ssim, record.creator_famname_ssm)
    |> Map.put(:creators_ssim, record[:creator_persname_ssm] ++ record[:creator_corpname_ssm] ++ record[:creator_famname_ssm])
    |> Map.put(:acqinfo_ssm, record[:acqinfo_ssim])
    |> Map.put(:access_subjects_ssm, record[:access_subjects_ssim])
    |> Map.put(:extent_teim, record[:extent_ssm])
    |> Map.put(:genreform_ssm, record[:genreform_sim])
  end

  defp extract_level(level_xpath) do
    level = level_xpath |> xpath(~x"./@level"s)
    otherlevel = level_xpath |> xpath(~x"./@otherlevel"s)
    extract_level(level, otherlevel)
  end

  defp extract_level("collection", _), do: ["Collection"]
  defp extract_level("recordgrp", _), do: ["Record Group", "Collection"]
  defp extract_level("subseries", _), do: ["Subseries", "Collection"]

  defp extract_level("otherlevel", otherlevel),
    do: otherlevel |> String.capitalize()
  defp extract_level(level, _), do: level |> String.capitalize
end

# to_field "normalized_title_ssm" do |_record, accumulator, context|
#   dates = Plantain::NormalizedDate.new(
#     context.output_hash["unitdate_inclusive_ssm"],
#     context.output_hash["unitdate_bulk_ssim"],
#     context.output_hash["unitdate_other_ssim"]
#   ).to_s
#   title = context.output_hash["title_ssm"].first
#   accumulator << Plantain::NormalizedTitle.new(title, dates).to_s
# end
#
# to_field "normalized_date_ssm" do |_record, accumulator, context|
#   accumulator << Plantain::NormalizedDate.new(
#     context.output_hash["unitdate_inclusive_ssm"],
#     context.output_hash["unitdate_bulk_ssim"],
#     context.output_hash["unitdate_other_ssim"]
#   ).to_s
# end
#
# to_field "collection_ssm" do |_record, accumulator, context|
#   accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
# end
# to_field "collection_sim" do |_record, accumulator, context|
#   accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
# end
# to_field "collection_ssi" do |_record, accumulator, context|
#   accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
# end
# to_field "collection_title_tesim" do |_record, accumulator, context|
#   accumulator.concat context.output_hash.fetch("normalized_title_ssm", [])
# end
#
# to_field "repository_ssm" do |_record, accumulator, context|
#   accumulator << context.clipboard[:repository]
# end
#
# to_field "repository_sim" do |_record, accumulator, context|
#   accumulator << context.clipboard[:repository]
# end
#
# to_field "has_online_content_ssim", extract_xpath(".//dao") do |_record, accumulator|
#   accumulator.replace([accumulator.any?])
# end
#
# to_field "digital_objects_ssm", extract_xpath("/ead/archdesc/did/dao|/ead/archdesc/dao", to_text: false) do |_record, accumulator|
#   accumulator.map! do |dao|
#     label = dao.attributes["title"]&.value ||
#             dao.xpath("daodesc/p")&.text
#     href = (dao.attributes["href"] || dao.attributes["xlink:href"])&.value
#     Arclight::DigitalObject.new(label: label, href: href).to_json
#   end
# end
#
# to_field "date_range_sim", extract_xpath("/ead/archdesc/did/unitdate/@normal", to_text: false) do |_record, accumulator|
#   range = Plantain::YearRange.new
#   next range.years if accumulator.blank?
#
#   ranges = accumulator.map(&:to_s)
#   range << range.parse_ranges(ranges)
#   accumulator.replace range.years
# end
#
# SEARCHABLE_NOTES_FIELDS.map do |selector|
#   to_field "#{selector}_ssm", extract_xpath("/ead/archdesc/#{selector}/*[local-name()!='head']", to_text: false)
#   to_field "#{selector}_heading_ssm", extract_xpath("/ead/archdesc/#{selector}/head") unless selector == "prefercite"
#   to_field "#{selector}_teim", extract_xpath("/ead/archdesc/#{selector}/*[local-name()!='head']")
# end
#
# DID_SEARCHABLE_NOTES_FIELDS.map do |selector|
#   to_field "#{selector}_ssm", extract_xpath("/ead/archdesc/did/#{selector}", to_text: false)
# end
#
# NAME_ELEMENTS.map do |selector|
#   to_field "names_coll_ssim", extract_xpath("/ead/archdesc/controlaccess/#{selector}")
#   to_field "names_ssim", extract_xpath("//#{selector}")
#   to_field "#{selector}_ssm", extract_xpath("//#{selector}")
# end
#
# to_field "corpname_sim", extract_xpath("//corpname")
#
# to_field "language_sim", extract_xpath("/ead/archdesc/did/langmaterial")
# to_field "language_ssm", extract_xpath("/ead/archdesc/did/langmaterial")
#
# to_field "descrules_ssm", extract_xpath("/ead/eadheader/profiledesc/descrules")
