defmodule MegaParser.YearRange do
  def to_string(nil), do: nil
  def to_string(dates = [hd | _]) when is_binary(hd) do
    years(dates)
    |> MegaParser.YearRange.to_string
  end
  def to_string([date]) when is_integer(date) do
    "#{date}"
  end
  def to_string([start_date, end_date]) when is_integer(start_date) and is_integer(end_date) do
    "#{start_date}-#{end_date}"
  end
  def to_string(dates = [hd | rest]) when is_list(dates) and is_integer(hd) do
    to_string(dates, has_gap?(dates))
  end
  def to_string(dates, false) do
    {min, max} = Enum.min_max(dates)
    "#{min}-#{max}"
  end
  def to_string(dates, true) do
    dates
    |> date_streaks([])
    |> Enum.map(&MegaParser.YearRange.to_string/1)
    |> Enum.join(", ")
  end

  defp date_streaks(dates, acc) do
    dates
    |> date_streaks([], acc)
  end
  defp date_streaks([date], local_acc, acc) do
    local_acc = local_acc ++ [date]
    acc = acc ++ [local_acc]
  end
  defp date_streaks([first | (next = [second | _])], local_acc, acc) when first+1 == second do
    local_acc = local_acc ++ [first]
    date_streaks(next, local_acc, acc)
  end
  defp date_streaks([first | (next = [second | _])], local_acc, acc) when first+1 != second do
    local_acc = local_acc ++ [first]
    acc = acc ++ [local_acc]
    date_streaks(next, [], acc)
  end

  defp has_gap?(dates) do
    {min, max} = Enum.min_max(dates)
    !(((min..max) |> Enum.to_list) == dates)
  end

  def years(dates) when is_list(dates) do
    dates
    |> Enum.flat_map(&parse_range/1)
    |> Enum.uniq
  end
  def parse_range(nil), do: nil
  def parse_range([start_year]) do
    [start_year]
  end
  def parse_range([start_year, end_year]) when start_year <= end_year do
    (start_year..end_year)
    |> Enum.to_list
  end
  def parse_range(date) do
    date
    |> String.split("/")
    |> Enum.map(&iso8601_to_year/1)
    |> parse_range
  end

  def iso8601_to_year(iso_8601) when is_binary(iso_8601) do
    iso_8601
    |> String.split("-")
    |> hd
    |> String.slice(0..3)
    |> String.to_integer
  end
end
