defmodule MegaParser.NormalizedDate do
  alias MegaParser.YearRange
  def to_string(_, _, other) when other != nil, do: other |> date_to_string
  def to_string(nil, _, other) when other == nil, do: nil
  def to_string(inclusive, nil, nil) when is_list(inclusive) do
    try do
    inclusive
    |> Enum.map(&String.replace(&1, "-","/"))
    |> YearRange.to_string
    rescue
      ArgumentError -> inclusive |> Enum.join(", ")
    end
  end
  def to_string(inclusive, bulk, nil) when is_list(inclusive) do
    "#{MegaParser.NormalizedDate.to_string(inclusive, nil, nil)}, bulk #{date_to_string(bulk)}"
  end

  defp date_to_string(date) when is_binary(date), do: date_to_string([date])
  defp date_to_string(date) when is_list(date) do
    date
    |> Enum.map(&String.trim/1)
    |> Enum.join(", ")
  end
end
