defmodule MegaParser do
  import Meeseeks.XPath

  defmodule Selector.Component do
    use Meeseeks.Selector

    defstruct value: ""

    def match(_selector, %{tag: "c"}, _document, _context), do: true
    def match(_selector, %{tag: "c0" <> <<_digit::bytes-size(1)>>}, _document, _context), do: true
    def match(_selector, %{tag: "c10"}, _document, _context), do: true
    def match(_selector, %{tag: "c11"}, _document, _context), do: true
    def match(_selector, %{tag: "c12"}, _document, _context), do: true
    def match(_selector, _node, _document, _context), do: false
  end

  @moduledoc """
  Documentation for MegaParser.
  """

  def parse(file) when is_binary(file) do
    parsed_file =
      file
      |> Meeseeks.parse(:xml)

    parent_record = parent_record(parsed_file)
    components = components(parsed_file, parent_record)

    parent_record
    |> Map.put(:components, components)
  end

  defp components(parsed_file, parent_record) do
    parsed_file
    |> Meeseeks.all(%Selector.Component{})
    |> Enum.map(&convert_component(&1, parent_record))
    |> insert_sort
    |> Enum.map(&process_component(&1, parent_record))
  end

  defp convert_component(component, parent_record) do
    %{
      ref_ssi: component |> Meeseeks.attr("id"),
      has_online_content_ssim: [component |> Meeseeks.one(xpath(".//dao")) != nil],
      geogname_sim: component |> extract_text("./controllaccess/geogname"),
      level_ssm: component |> extract_level,
      component_level_isim: [
        component
        |> Meeseeks.all(%Meeseeks.Selector.Element{
          combinator: %Meeseeks.Selector.Combinator.AncestorsOrSelf{
            selector: %Selector.Component{}
          }
        })
        |> length
      ],
      containers_ssim: component |> Meeseeks.all(xpath("./did/container")) |> container_string,
      parent_ssim: component |> get_parents(parent_record)
    }
  end

  def get_parents(component, parent_record) do
    parent_ids =
      component
      |> Meeseeks.all(%Meeseeks.Selector.Element{
        combinator: %Meeseeks.Selector.Combinator.Ancestors{
          selector: %Selector.Component{}
        }
      })
      |> Enum.map(&Meeseeks.attr(&1, "id"))
      |> Enum.reverse
      |> Enum.drop(1)
    [parent_record.id] ++ parent_ids
  end

  defp insert_sort(components) when is_list(components) do
    components
    |> Enum.map(&insert_sort(&1, components))
  end

  defp insert_sort(component, components) do
    component
    |> Map.put(:sort_ii, Enum.find_index(components, fn x -> x == component end))
  end

  defp container_string(containers) when is_list(containers) do
    containers
    |> Enum.map(&container_string/1)
  end

  defp container_string(%{type: type, text: text}) do
    "#{type} #{text}" |> String.trim()
  end

  defp container_string(container = %{}) do
    type = container |> Meeseeks.attr("type")
    text = container |> Meeseeks.text()

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

  defp extract_text(ead, xpath) do
    ead |> Meeseeks.all(xpath(xpath)) |> Enum.map(&Meeseeks.text/1)
  end

  defp parent_record(parsed_file) do
    ead =
      parsed_file
      |> Meeseeks.one(xpath("/ead"))

    %{
      id:
        ead
        |> Meeseeks.one(xpath("./eadheader/eadid"))
        |> Meeseeks.text()
        |> String.replace(".", "-"),
      title_filing_si: ead |> extract_text("./eadheader/filedesc/titlestmt/titleproper[@type='filing']"),
      title_ssm:
        ead |> Meeseeks.all(xpath("./archdesc/did/unittitle")) |> Enum.map(&Meeseeks.text/1),
      ead_ssi: ead |> Meeseeks.one(xpath("./eadheader/eadid")) |> Meeseeks.text(),
      unitdate_ssm: ead |> extract_text("./archdesc/did/unitdate"),
      unitdate_bulk_ssim: ead |> extract_text("./archdesc/did/unitdate[@type='bulk']"),
      unitdate_inclusive_ssm: ead |> extract_text("./archdesc/did/unitdate[@type='inclusive']"),
      unitdate_other_ssim: ead |> extract_text("./archdesc/did/unitdate[not(@type)]"),
      unitid_ssm: ead |> extract_text("./archdesc/did/unitid"),
      geogname_ssm: ead |> extract_text("./archdesc/controlaccess/geogname"),
      creator_ssm: ead |> extract_text("./archdesc/did/origination"),
      creator_persname_ssm: ead |> extract_text("./archdesc/did/origination/persname"),
      creator_corpname_ssm: ead |> extract_text("./archdesc/did/origination/corpname"),
      creator_famname_ssm: ead |> extract_text("./archdesc/did/origination/famname"),
      persname_sim: ead |> extract_text("//persname"),
      access_terms_ssm: ead |> extract_text("./archdesc/userestrict/*[local-name()!='head']"),
      acqinfo_ssim: ead |> extract_text("./archdesc/descgrp/acqinfo/*[local-name()!='head']"),
      collection_unitid_ssm: ead |> extract_text("./archdesc/did/unitid"),
      access_subjects_ssim:
        ead
        |> extract_text(
          "./archdesc/controlaccess/*[self::subject or self::function or self::occupation or self::genreform]"
        ),
      extent_ssm: ead |> extract_text("./archdesc/did/physdesc/extent"),
      genreform_sim: ead |> extract_text("./archdesc/controlaccess/genreform"),
      level_sim: ead |> Meeseeks.one(xpath("./archdesc")) |> extract_level
    }
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
    |> Map.put(
      :creators_ssim,
      record[:creator_persname_ssm] ++
        record[:creator_corpname_ssm] ++ record[:creator_famname_ssm]
    )
    |> Map.put(:acqinfo_ssm, record[:acqinfo_ssim])
    |> Map.put(:access_subjects_ssm, record[:access_subjects_ssim])
    |> Map.put(:extent_teim, record[:extent_ssm])
    |> Map.put(:genreform_ssm, record[:genreform_sim])
  end

  defp extract_level(level_node) do
    level = level_node |> Meeseeks.attr("level")
    otherlevel = level_node |> Meeseeks.attr("otherlevel")
    extract_level(level, otherlevel)
  end

  defp extract_level("collection", _), do: ["Collection"]
  defp extract_level("recordgrp", _), do: ["Record Group", "Collection"]
  defp extract_level("subseries", _), do: ["Subseries", "Collection"]

  defp extract_level("otherlevel", nil), do: []

  defp extract_level("otherlevel", otherlevel),
    do: otherlevel |> String.capitalize()

  defp extract_level(level, _), do: level |> String.capitalize()
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
