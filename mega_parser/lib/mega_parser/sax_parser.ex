defmodule MegaParser.SaxParser do
  @behaviour Saxy.Handler
  def handle_event(:start_document, prolog, state) do
    {:ok, %{tag_stack: [], document: %{}}}
  end

  def handle_event(:end_document, _data, state) do
    {:ok, state}
  end

  def handle_event(:start_element, tag = {name, attributes}, state) do
    {:ok, state |> append_tag(tag) |> handle_tag(tag)}
  end


  def handle_tag(state, tag = {"c", _attributes}), do: state |> add_component(tag)
  def handle_tag(state, tag = {"c0" <> <<_digit::bytes-size(1)>>, _attributes}), do: state |> add_component(tag)
  def handle_tag(state, tag = {"c11", _attributes}), do: state |> add_component(tag)
  def handle_tag(state, tag = {"c12", _attributes}), do: state |> add_component(tag)
  defp add_component(state = %{current_component: current_component = %{}}, tag = {name, attrs}) do
    state = 
      state
      |> Map.put(:component_stack, [current_component | (state[:component_stack] || [])])
    Map.put(state, :current_component, build_component(state, tag))
  end
  defp add_component(state, tag = {name, attrs}) do
    state
    |> Map.put(:current_component, build_component(state, tag))
  end

  defp build_component(state, tag = {name, attrs}) do
    id = attrs |> List.keyfind("id", 0, {:notfound, nil}) |> elem(1)
    level = attrs |> extract_attr("level")
    otherlevel = attrs |> extract_attr("otherlevel")
    component_level = state |> component_level
    parent_ids = state |> parent_ids
    %{id: id, level: level, other_level: otherlevel, component_level: [component_level], parent_ids: parent_ids}
  end
  defp component_level(%{tag_stack: stack}) do
    stack
    |> Enum.filter(fn(x) -> elem(x, 0) in ["c", "c01"] end)
    |> length
  end
  defp parent_ids(stack = %{component_stack: component_stack}) do
    [stack.document.id | Enum.map(component_stack, fn(x) -> x.id end)]
  end
  defp parent_ids(stack) do
    [stack.document.id]
  end
  def handle_tag(state, tag = {"archdesc", _attributes}), do: state |> add_level(tag)
  def handle_tag(state, tag = {"unitdate", attrs}) do
    normal = attrs |> extract_attr("normal")
    state
    |> put_in([:document, :unitdate_normal], normal)
  end
  def handle_tag(state = %{current_component: %{}}, tag = {"dao", _attrs}) do
    state
    |> put_in([:current_component, :has_online_content], [true])
  end
  defp add_level(state, tag = {name, attrs}) do
    level = attrs |> extract_attr("level")
    otherlevel = attrs |> extract_attr("otherlevel")
    state
    |> put_in([:document, :level], MegaParser.extract_level(level, otherlevel))
  end
  def handle_tag(state, _tag), do: state

  defp append_tag(state, tag) do
    state
    |> Map.put(:tag_stack, [tag | state.tag_stack])
  end


  defp extract_attr(attrs, attr) do
    attrs |> List.keyfind(attr, 0, {:notfound, nil}) |> elem(1)
  end

  def handle_event(:end_element, "c", state = %{tag_stack: [hd | tail], current_component: component = %{}}) do
    {:ok, state |> Map.put(:tag_stack, tail) |> end_component(component)}
  end
  def handle_event(:end_element, "c01", state = %{tag_stack: [hd | tail], current_component: component = %{}}) do
    {:ok, state |> Map.put(:tag_stack, tail) |> end_component(component)}
  end
  defp end_component(state = %{component_stack: [hd | rest]}, component) do
    state
    |> Map.delete(:current_component)
    |> Map.put(:current_component, hd)
    |> Map.put(:component_stack, rest)
    |> put_in([:document, :components], [component | (state.document[:components] || [])])
  end
  defp end_component(state, component) do
    state
    |> Map.delete(:current_component)
    |> put_in([:document, :components], [component | (state.document[:components] || [])])
  end
  def handle_event(:end_element, name, state = %{tag_stack: [hd | tail]}) do
    {:ok, state |> Map.put(:tag_stack, tail)}
  end

  ## Extract ead ID
  def handle_event(:characters, chars, state = %{tag_stack: [{"eadid", _} | _extra]}) do
    state =
      state
      |> put_in([:document, :id], chars |> clean_string)

    {:ok, state}
  end

  # Extract Filing Title
  def handle_event(
        :characters,
        chars,
        state = %{
          tag_stack: [
            {"titleproper", attrs},
            {"titlestmt", _},
            {"filedesc", _},
            {"eadheader", _} | _extra
          ]
        }
      ) do
    state =
      case attrs |> List.keyfind("type", 0) do
        {"type", "filing"} ->
          state
          |> add_doc_property(:title_filing, chars)
        nil ->
          state
      end

    {:ok, state}
  end

  # Extract Title
  def handle_event(
        :characters,
        chars,
        state = %{
          tag_stack: [
            {"unittitle", _},
            {"did", _},
            {"archdesc", _} | _extra
          ]
        }
      ) do
    state =
      state
      |> add_doc_property(:title, chars)

    {:ok, state}
  end

  # Extract UnitDate
  def handle_event(
        :characters,
        chars,
        state = %{
          tag_stack: [
            {"unitdate", attrs},
            {"did", _},
            {"archdesc", _} | _extra
          ]
        }
      ) do
        type = attrs |> List.keyfind("type", 0, {:notfound, nil}) |> elem(1)
        {:ok, state |> add_doc_property(:unitdate, chars) |> add_unitdate(type, chars)}
  end

  def handle_event(
        :characters,
        chars,
        state = %{
          tag_stack: [
            {"geogname", _attrs},
            {"controlaccess", _} | _extra
          ],
          current_component: %{}
        }
      ) do
        {:ok, state |> add_component_property(:geogname, chars)}
  end

  defp add_unitdate(state, "bulk", chars), do: state |> add_doc_property(:unitdate_bulk, chars)
  defp add_unitdate(state, "inclusive", chars), do: state |> add_doc_property(:unitdate_inclusive, chars)
  defp add_unitdate(state, nil, chars) do
    state |> add_doc_property(:unitdate_other, chars)
  end
  defp add_unitdate(state, _type, _chars), do: state

  defp add_doc_property(state, property, chars) do
    state
    |> put_in([:document, property], [chars |> clean_string | state.document[property] || []])
  end

  defp add_component_property(state, property, chars) do
    state
    |> put_in([:current_component, property], [chars |> clean_string | state.document[property] || []])
  end

  def handle_event(:characters, chars, state) do
    {:ok, state}
  end

  defp clean_string(string) do
    string
    |> String.replace("\n", "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
