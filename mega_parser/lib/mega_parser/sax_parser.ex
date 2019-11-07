defmodule MegaParser.SaxParser do
  defmodule Document do
    defstruct id: nil, children: []
  end

  defmodule Element do
    defstruct text: "", parent_element: nil
  end

  defmodule ParseContainer do
    defstruct document: nil, current_element: nil, parent_element: nil, accumulator: []
  end

  @behaviour Saxy.Handler
  def handle_event(:start_document, prolog, state) do
    IO.inspect("Start parsing document")
    {:ok, %{tag_stack: [], document: %{}}}
  end

  def handle_event(:end_document, _data, state) do
    {:ok, state}
  end

  def handle_event(:start_element, tag = {"c", _attributes}, state), do: {:ok, state |> add_component(tag)}
  def handle_event(:start_element, tag = {"c01", _attributes}, state), do: {:ok, state |> add_component(tag)}
  defp add_component(state, tag = {name, attrs}) do
    id = attrs |> List.keyfind("id", 0, {:notfound, nil}) |> elem(1)
    state
    |> Map.put(:current_component, %{id: id})
    |> Map.put(:tag_stack, [tag | state.tag_stack])
  end
  def handle_event(:start_element, {name, attributes}, state) do
    state =
      state
      |> Map.put(:tag_stack, [{name, attributes} | state.tag_stack])

    {:ok, state}
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

  require IEx

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
