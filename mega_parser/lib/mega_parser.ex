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
    |> put_multiple([:access_subjects_ssim, :access_subjects_ssm], document[:access_subjects] || [])
    |> Map.put(:has_online_content_ssim, document[:has_online_content])
    |> Map.put(:digital_objects_ssm, document[:digital_objects] || [])
    |> put_multiple([:extent_ssm, :extent_teim], document[:extent] || [])
    |> put_multiple([:genreform_ssm, :genreform_sim], document[:genreform] || [])
    |> Map.merge(searchable_fields_map(document))
  end

  defp searchable_fields_map(document) do
    MegaParser.SaxParser.searchable_notes_fields
    |> Enum.reduce(%{}, &apply_note_field(&1, &2, document))
  end

  def apply_note_field(key, map, document) do
    map
    |> Map.put(:"#{key}_teim", document[:"#{key}"] || [])
    |> Map.put(:"#{key}_heading_ssm", document[:"#{key}_heading"] || [])
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
