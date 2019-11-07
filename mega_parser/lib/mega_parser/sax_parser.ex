defmodule MegaParser.SaxParser do
  @behaviour Saxy.Handler
  def handle_event(:start_document, prolog, state) do
    IO.inspect("Start parsing document")
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
  defp add_component(state, tag = {name, attrs}) do
    id = attrs |> List.keyfind("id", 0, {:notfound, nil}) |> elem(1)
    state
    |> Map.put(:current_component, %{id: id})
  end
  def handle_tag(state, tag = {"archdesc", _attributes}), do: state |> add_level(tag)
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
  defp end_component(state, component) do
    state
    |> Map.delete(:current_component)
    |> put_in([:document, :components], [component | (state.document[:components] || [])])
  end
  def handle_event(:end_element, name, state = %{tag_stack: [hd | tail]}) do
    {:ok, state |> Map.put(:tag_stack, tail)}
  end

  def handle_event(:characters, chars, state = %{tag_stack: [{"eadid", _} | _extra]}) do
    state =
      state
      |> put_in([:document, :id], chars |> clean_string)

    {:ok, state}
  end

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

  defp add_unitdate(state, "bulk", chars), do: state |> add_doc_property(:unitdate_bulk, chars)
  defp add_unitdate(state, "inclusive", chars), do: state |> add_doc_property(:unitdate_inclusive, chars)
  defp add_unitdate(state, nil, chars), do: state |> add_doc_property(:unitdate_other, chars)
  defp add_unitdate(state, _type, _chars), do: state

  defp add_doc_property(state, property, chars) do
    state
    |> put_in([:document, property], [chars |> clean_string | state.document[property] || []])
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
