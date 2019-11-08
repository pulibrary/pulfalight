defmodule MegaParser.MeeseeksParser do
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

  def parse(file) do
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
    |> Enum.map(&MegaParser.convert_standard_component(&1, parent_record))
    |> insert_sort
  end

  defp convert_component(component, parent_record) do
    %{
      id: component |> Meeseeks.attr("id"),
      has_online_content: [component |> Meeseeks.one(xpath(".//dao")) != nil],
      geogname: component |> extract_text("./controlaccess/geogname"),

      level: component |> Meeseeks.attr("level"),
      other_level: component |> Meeseeks.attr("otherlevel"),
      component_level: [
        component
        |> Meeseeks.all(%Meeseeks.Selector.Element{
          combinator: %Meeseeks.Selector.Combinator.AncestorsOrSelf{
            selector: %Selector.Component{}
          }
        })
        |> length
      ],
      containers: component |> Meeseeks.all(xpath("./did/container")) |> MegaParser.container_string,
      parent_ids: component |> get_parents(parent_record)
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
        |> Meeseeks.text(),
      title_filing: ead |> extract_text("./eadheader/filedesc/titlestmt/titleproper[@type='filing']"),
      title:
        ead |> Meeseeks.all(xpath("./archdesc/did/unittitle")) |> Enum.map(&Meeseeks.text/1),
      ead_ssi: ead |> Meeseeks.one(xpath("./eadheader/eadid")) |> Meeseeks.text(),
      unitdate: ead |> extract_text("./archdesc/did/unitdate"),
      unitdate_bulk: ead |> extract_text("./archdesc/did/unitdate[@type='bulk']"),
      unitdate_inclusive: ead |> extract_text("./archdesc/did/unitdate[@type='inclusive']"),
      unitdate_other: ead |> extract_text("./archdesc/did/unitdate[not(@type)]"),
      unitid: ead |> extract_text("./archdesc/did/unitid"),
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
      level: ead |> Meeseeks.one(xpath("./archdesc")) |> MegaParser.extract_level,
      unitdate_normal: ead |> Meeseeks.one(xpath("./did/unitdate")) |> Meeseeks.attr("normal")
    }
    |> MegaParser.convert_standard_parent
  end
end
