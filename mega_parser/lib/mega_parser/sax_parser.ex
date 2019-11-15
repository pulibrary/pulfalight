defmodule MegaParser.SaxParser do
  use MegaParser.SaxTagStacker

  @searchable_notes_fields [
    "accessrestrict",
    "accruals",
    "altformavail",
    "appraisal",
    "arrangement",
    "bibliography",
    "bioghist",
    "custodhist",
    "fileplan",
    "note",
    "odd",
    "originalsloc",
    "otherfindaid",
    "phystech",
    "prefercite",
    "processinfo",
    "relatedmaterial",
    "scopecontent",
    "separatedmaterial",
    "userestrict"
  ]

  @components ["c"] ++
                for(
                  n <- 1..12,
                  do:
                    n
                    |> Integer.to_string()
                    |> String.pad_leading(2, "0")
                    |> (fn x -> "c" <> x end).()
                )

  def searchable_notes_fields do
    @searchable_notes_fields
  end

  def initial_state do
    %{tag_stack: [], document: %{}, component_counter: 0}
  end

  def handle_tag_start(state, tag = {name, _attributes}) when name in @components,
    do: state |> add_component(tag)

  def handle_tag_start(state, tag = {"archdesc", _attributes}), do: state |> add_level(tag)

  def handle_tag_start(state, {"unitdate", attrs}) do
    normal = attrs |> extract_attr("normal")

    state
    |> put_in([:document, :unitdate_normal], normal)
  end

  def handle_tag_start(state = %{current_component: %{}}, {"dao", _attrs}) do
    state
    |> put_in([:current_component, :has_online_content], [true])
    |> put_in([:document, :has_online_content], [true])
  end

  def handle_tag_start(state, _tag), do: state

  defp add_component(state = %{current_component: current_component = %{}}, tag = {_name, _attrs}) do
    state =
      state
      |> Map.put(:component_stack, [current_component | state[:component_stack] || []])

    Map.put(state, :current_component, build_component(state, tag))
    |> Map.put(:component_counter, state.component_counter + 1)
  end

  defp add_component(state, tag = {_name, _attrs}) do
    state
    |> Map.put(:current_component, build_component(state, tag))
    |> Map.put(:component_counter, state.component_counter + 1)
  end

  defp build_component(state, {_name, attrs}) do
    id = attrs |> List.keyfind("id", 0, {:notfound, nil}) |> elem(1)
    level = attrs |> extract_attr("level")
    otherlevel = attrs |> extract_attr("otherlevel")
    component_level = state |> component_level
    parent_ids = state |> parent_ids
    parent_unittitles = state |> parent_unittitles

    %{
      id: id,
      level: level,
      other_level: otherlevel,
      component_level: [component_level],
      parent_ids: parent_ids,
      parent_unittitles: parent_unittitles,
      sort: state.component_counter
    }
  end

  defp component_level(%{tag_stack: stack}) do
    stack
    |> Enum.filter(fn x -> elem(x, 0) in @components end)
    |> length
  end

  defp parent_ids(stack = %{component_stack: component_stack}) do
    [stack.document.id | Enum.map(component_stack, fn x -> x.id end)]
  end

  defp parent_ids(stack) do
    [stack.document.id]
  end

  defp parent_unittitles(stack = %{component_stack: component_stack}) do
    [
      stack.document.normalized_title
      | Enum.map(component_stack, fn x -> x.normalized_title end)
    ]
  end

  defp parent_unittitles(stack) do
    [stack.document.normalized_title]
  end

  defp add_level(state, {_name, attrs}) do
    level = attrs |> extract_attr("level")
    otherlevel = attrs |> extract_attr("otherlevel")

    state
    |> put_in([:document, :level], MegaParser.extract_level(level, otherlevel))
  end

  defp append_tag(state, tag) do
    state
    |> Map.put(:tag_stack, [tag | state.tag_stack])
  end

  defp extract_attr(attrs, attr) do
    attrs |> List.keyfind(attr, 0, {:notfound, nil}) |> elem(1)
  end

  def drop_tag_stack(state = %{tag_stack: []}), do: state

  def drop_tag_stack(state = %{tag_stack: [_hd | tail]}) do
    state
    |> Map.put(:tag_stack, tail)
  end

  def handle_tag_end(
        state = %{tag_stack: [{"archdesc", _} | _rest]},
        "did"
      ) do
    state
    |> put_in([:document, :normalized_title], MegaParser.normalized_title(state.document) || nil)
  end

  def handle_tag_end(
        state = %{current_component: component = %{}},
        tag
      )
      when tag in @components do
    state
    |> Map.put(:current_component, reverse_fields(component))
    |> end_component(component)
  end

  def handle_tag_end(state, _tag), do: state

  defp end_component(state = %{component_stack: [hd | rest]}, component) do
    state
    |> Map.delete(:current_component)
    |> Map.put(:current_component, hd)
    |> Map.put(:component_stack, rest)
    |> put_in([:document, :components], [component | state.document[:components] || []])
  end

  defp end_component(state, component) do
    state
    |> Map.delete(:current_component)
    |> put_in([:document, :components], [component | state.document[:components] || []])
  end

  ## Extract ead ID
  def handle_text(state = %{tag_stack: [{"eadid", _} | _extra]}, chars) do
    state
    |> put_in([:document, :id], chars |> clean_string)
  end

  # Extract Filing Title
  def handle_text(
        state = %{
          tag_stack: [
            {"titleproper", attrs},
            {"titlestmt", _},
            {"filedesc", _},
            {"eadheader", _} | _extra
          ]
        },
        chars
      ) do
    case attrs |> List.keyfind("type", 0) do
      {"type", "filing"} ->
        state
        |> add_doc_property(:title_filing, chars)

      nil ->
        state
    end
  end

  # Extract Title
  def handle_text(
        state = %{
          tag_stack: [
            {"unittitle", _},
            {"did", _} | _rest
          ],
          current_component: %{}
        },
        chars
      ) do
    state = add_component_property(state, :title, chars)

    state
    |> put_in(
      [:current_component, :normalized_title],
      MegaParser.normalized_title(state.current_component) |> Enum.at(0) || nil
    )
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"unittitle", _},
            {"did", _} | _rest
          ]
        },
        chars
      ) do
    state
    |> add_doc_property(:title, chars)
  end

  # Extract UnitID
  def handle_text(
        state = %{
          tag_stack: [
            {"unitid", _},
            {"did", _},
            {"archdesc", _} | _extra
          ]
        },
        chars
      ) do
    state
    |> add_doc_property(:unitid, chars)
  end

  # Extract UnitDate
  def handle_text(
        state = %{
          tag_stack: [
            {"unitdate", attrs},
            {"did", _},
            {"archdesc", _} | _extra
          ]
        },
        chars
      ) do
    type = attrs |> List.keyfind("type", 0, {:notfound, nil}) |> elem(1)

    state
    |> add_doc_property(:unitdate, chars)
    |> add_unitdate(type, chars)
  end

  # Extract Containers
  def handle_text(
        state = %{
          tag_stack: [
            {"container", attrs},
            {"did", _} | _extra
          ],
          current_component: %{}
        },
        chars
      ) do
    type = attrs |> List.keyfind("type", 0, {:notfound, nil}) |> elem(1)

    state
    |> add_component_property(
      :containers,
      MegaParser.container_string(%{type: type, text: chars})
    )
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"geogname", _attrs},
            {"controlaccess", _} | _extra
          ],
          current_component: %{}
        },
        chars
      ) do
    state |> add_component_property(:geogname, chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"geogname", _attrs},
            {"controlaccess", _} | _extra
          ]
        },
        chars
      ) do
    state |> add_doc_property(:geogname, chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {access_tag, _attrs},
            {"controlaccess", _} | _extra
          ]
        },
        chars
      )
      when access_tag in ["subject", "function", "occupation", "genreform"] do
    state
    |> add_doc_property(:access_subjects, chars)
    |> add_doc_property(:"#{access_tag}", chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {creator_type, _attrs},
            {"origination", _},
            {"did", _} | _extra
          ]
        },
        chars
      ) do
    if(creator_type == "persname") do
      state = state |> add_doc_property(:all_persname, chars)
    end

    state
    |> add_doc_property(:creator, chars)
    |> add_doc_property(:"creator_#{creator_type}", chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"persname", _attrs} | _extra
          ]
        },
        chars
      ) do
    state
    |> add_doc_property(:all_persname, chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"userestrict", _attrs},
            {"archdesc", _} | _extra
          ]
        },
        chars
      ) do
    state
    |> add_doc_property(:userestrict, chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"acqinfo", _attrs} | _extra
          ]
        },
        chars
      ) do
    state
    |> add_doc_property(:acqinfo, chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"extent", _attrs},
            {"physdesc", _},
            {"did", _} | _extra
          ]
        },
        chars
      ) do
    state
    |> add_doc_property(:extent, chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {field, _attrs},
            {"archdesc", _} | _extra
          ]
        },
        chars
      )
      when field in @searchable_notes_fields do
    state
    |> add_doc_property(:"#{field}", chars)
  end

  def handle_text(
        state = %{
          tag_stack: [
            {"head", _},
            {field, _attrs},
            {"archdesc", _} | _extra
          ]
        },
        chars
      )
      when field in @searchable_notes_fields do
    state
    |> add_doc_property(:"#{field}_heading", chars)
  end

  def handle_text(state, _chars), do: state

  defp add_unitdate(state, "bulk", chars), do: state |> add_doc_property(:unitdate_bulk, chars)

  defp add_unitdate(state, "inclusive", chars),
    do: state |> add_doc_property(:unitdate_inclusive, chars)

  defp add_unitdate(state, nil, chars) do
    state |> add_doc_property(:unitdate_other, chars)
  end

  defp add_unitdate(state, _type, _chars), do: state

  defp add_doc_property(state, property, chars) do
    state
    |> put_in([:document, property],
      [(chars |> clean_string) | (state.document[property] || [])]
      # (state.document[property] || []) ++ [chars |> clean_string]
    )
  end

  defp add_component_property(state, property, chars) do
    state
    |> put_in(
      [:current_component, property],

      [(chars |> clean_string) | (state.current_component[property] || [])]
      # (state.current_component[property] || []) ++ [chars |> clean_string]
    )
  end

  defp clean_string(string) do
    string
    # |> String.replace("\n", "")
    |> remove_whitespace
    |> String.trim()
  end

  defp remove_whitespace(string) do
    string
    |> remove_whitespace([])
  end
  defp remove_whitespace("", acc) do
    acc
    |> Enum.reverse
    |> Enum.join("")
  end
  defp remove_whitespace(" " <> string, acc = [" " | _extra]) do
    remove_whitespace(string, acc)
  end
  defp remove_whitespace("\n" <> string, acc) do
    remove_whitespace(string, acc)
  end
  defp remove_whitespace(<<digit::bytes-size(1)>> <> string, acc) do
    acc = [digit | acc]
    remove_whitespace(string, acc)
  end

  defp final_cleanup(state = %{document: document}) do
    state
    |> Map.put(:document, reverse_fields(document))
  end

  defp reverse_fields(document) do
    document
    |> Enum.reduce(%{}, &reverse_values/2)
  end

  defp reverse_values({key, values}, map) when is_list(values) do
    map
    |> Map.put(key, Enum.reverse(values))
  end
  defp reverse_values({key, values}, map) do
    map
    |> Map.put(key, values)
  end
end
