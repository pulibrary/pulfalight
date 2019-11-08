defmodule MegaParser do
  alias MegaParser.MeeseeksParser
  @moduledoc """
  Documentation for MegaParser.
  """

  def parse(file) when is_binary(file) do
    MeeseeksParser.parse(file)
  end

  def parse(file, :sax) do
    parent_record = File.read!(file)
                    |> Saxy.parse_string(MegaParser.SaxParser, [])
                    |> elem(1)
                    |> Map.get(:document)

    parent_converted = parent_record |> convert_standard_parent
    components_converted =
      parent_record
      |> Map.get(:components)
      |> Enum.map(&convert_standard_component(&1, parent_converted))

    parent_converted
    |> Map.put(:components, components_converted)
  end

  def convert_standard_component(component, parent_record) do
    %{}
    |> Map.put(:id, "#{parent_record.id}#{component.id}")
    |> Map.put(:ref_ssi, component.id)
    |> Map.put(:ead_ssi, parent_record.ead_ssi)
    |> put_multiple([:level_ssm, :level_sim], extract_level(component.level, component.other_level))
    |> put_multiple([:geogname_ssm, :geogname_sim], component[:geogname] || [])
    |> Map.put(:component_level_isim, component.component_level)
    |> Map.put(:parent_ssim, component.parent_ids)
    |> Map.put(:parent_ssi, component.parent_ids |> Enum.slice(-1..-1))
    |> Map.put(:has_online_content_ssim, component[:has_online_content])
    |> Map.put(:collection_unitid_ssm, parent_record.unitid_ssm)
    |> Map.put(:containers_ssim, component[:containers])
    |> Map.put(:parent_unittitles_ssm, component[:parent_unittitles])
    |> Map.put(:normalized_title_ssm, normalized_title(component))
    |> Map.put(:normalized_date_ssm, normalized_date(component))
    |> Map.put(:sort_ii, component[:sort])
  end

  def container_string(containers) when is_list(containers) do
    containers
    |> Enum.map(&container_string/1)
  end

  def container_string(%{type: type, text: text}) do
    "#{type} #{text}" |> String.trim()
  end

  def container_string(container = %{}) do
    type = container |> Meeseeks.attr("type")
    text = container |> Meeseeks.text()

    %{
      type: type,
      text: text
    }
    |> container_string
  end

  def convert_standard_parent(document) do
    %{}
    |> Map.put(:id, document.id |> String.replace(".", "-"))
    |> Map.put(:ead_ssi, document.id)
    |> put_multiple([:title_ssm, :title_teim], document.title)
    |> put_multiple([:level_sim], document.level)
    |> Map.put(:level_ssm, ["collection"])
    |> put_multiple([:unitid_ssm, :unitid_teim, :collection_unitid_ssm], document[:unitid])
    |> put_multiple([:normalized_title_ssm, :collection_ssm, :collection_sim, :collection_ssi, :collection_title_tesim], [normalized_title(document)])
    |> Map.put(:normalized_date_ssm, normalized_date(document))
    |> Map.put(:unitdate_ssm, document[:unitdate_inclusive] || document[:unitdate_bulk] || document[:unitdate_other])
    |> Map.put(:unitdate_bulk_ssim, document[:unitdate_bulk] || [])
    |> Map.put(:unitdate_inclusive_ssm, document[:unitdate_inclusive])
    |> Map.put(:unitdate_other_ssim, document[:unitdate_other] || [])
    |> Map.put(:date_range_sim, document[:unitdate_normal] |> MegaParser.YearRange.parse_range)
    |> put_multiple([:geogname_ssm, :geogname_sim, :places_sim, :places_ssim, :places_ssm], document[:geogname] || [])
    |> put_multiple([:creator_ssm, :creator_sim, :creator_ssim, :creators_ssim], document[:creator] || [])
    |> Map.put(:creator_sort, (document[:creator] || []) |> Enum.join(", "))
    |> put_multiple([:creator_corpname_ssm, :creator_corpname_sim, :creator_corpname_ssim], document[:creator_corpname] || [])
    |> put_multiple([:creator_persname_ssm, :creator_persname_sim, :creator_persname_ssim], document[:creator_persname] || [])
    |> put_multiple([:creator_famname_ssm, :creator_famname_sim, :creator_famname_ssim], document[:creator_famname] || [])
    |> put_multiple([:persname_sim], document[:all_persname] || [])
    |> put_multiple([:access_terms_ssm], document[:userestrict] || [])
    |> put_multiple([:acqinfo_ssm, :acqinfo_ssim], document[:acqinfo] || [])
  end

  defp put_multiple(map, keys, value) do
    keys
    |> Enum.reduce(map, fn(key, map) -> map |> Map.put(key, value) end)
  end

  def normalized_title(record) do
    normalized_title(record[:title], normalized_date(record))
  end
  def normalized_title(title, nil), do: title
  def normalized_title(title, [nil]), do: title
  def normalized_title(title, date), do: [title | date] |> Enum.join(", ")

  def normalized_date(record) do
    [MegaParser.NormalizedDate.to_string(record[:unitdate_inclusive], (record[:unitdate_bulk] || []) |> Enum.at(0), (record[:unitdate_other] || []) |> Enum.at(0))]
  end

  # defp process_parent_record(record) do
  #   record
  #   |> Map.put(:normalized_title_ssm, [normalized_title(record)])
  #   |> Map.put(:normalized_date_ssm, normalized_date(record))
  #   |> Map.put(:level_ssm, ["collection"])
  #   |> Map.put(:title_teim, record.title_ssm)
  #   |> Map.put(:unitid_teim, record.unitid_ssm)
  #   |> Map.put(:geogname_sim, record.geogname_ssm)
  #   |> Map.put(:places_sim, record.geogname_ssm)
  #   |> Map.put(:places_ssim, record.geogname_ssm)
  #   |> Map.put(:places_ssm, record.geogname_ssm)
  #   |> Map.put(:creator_sim, record.creator_ssm)
  #   |> Map.put(:creator_ssim, record.creator_ssm)
  #   |> Map.put(:creator_sort, Enum.join(record.creator_ssm, ", "))
  #   |> Map.put(:creator_persname_ssim, record.creator_persname_ssm)
  #   |> Map.put(:creator_corpname_ssim, record.creator_corpname_ssm)
  #   |> Map.put(:creator_corpname_sim, record.creator_corpname_ssm)
  #   |> Map.put(:creator_famname_ssim, record.creator_famname_ssm)
  #   |> Map.put(
  #     :creators_ssim,
  #     record[:creator_persname_ssm] ++
  #       record[:creator_corpname_ssm] ++ record[:creator_famname_ssm]
  #   )
  #   |> Map.put(:acqinfo_ssm, record[:acqinfo_ssim])
  #   |> Map.put(:access_subjects_ssm, record[:access_subjects_ssim])
  #   |> Map.put(:extent_teim, record[:extent_ssm])
  #   |> Map.put(:genreform_ssm, record[:genreform_sim])
  # end

  def extract_level(level_node) do
    level = level_node |> Meeseeks.attr("level")
    otherlevel = level_node |> Meeseeks.attr("otherlevel")
    extract_level(level, otherlevel)
  end

  def extract_level("collection", _), do: ["Collection"]
  def extract_level("recordgrp", _), do: ["Record Group", "Collection"]
  def extract_level("subseries", _), do: ["Subseries", "Collection"]

  def extract_level("otherlevel", nil), do: []

  def extract_level("otherlevel", otherlevel),
    do: otherlevel |> String.capitalize()

  def extract_level(level, _), do: level |> String.capitalize()
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
