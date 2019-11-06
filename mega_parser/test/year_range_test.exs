defmodule MegaParser.YearRangeTest do
  use ExUnit.Case
  doctest MegaParser.YearRange
  alias MegaParser.YearRange

  test "years" do
    assert length(YearRange.years(["1999", "2002/2003"])) == 3
    assert length(YearRange.years([])) == 0
    assert YearRange.years(["1999-01-01"]) == [1999]
    assert YearRange.years(["19990101"]) == [1999]
    assert YearRange.years(["1"]) == [1]
    assert YearRange.years(["1999/2000", "2001/2002"]) == [1999, 2000, 2001, 2002]
    assert YearRange.years(["1999/2005", "2002/2003", "2004/2004"]) == [1999, 2000, 2001, 2002, 2003, 2004, 2005]
  end

  test "to_string" do
    assert YearRange.to_string(nil) == nil
    assert YearRange.to_string([1999]) == "1999"
    assert YearRange.to_string([1999, 2000]) == "1999-2000"
    assert YearRange.to_string((1900..2000) |> Enum.to_list) == "1900-2000"
    assert YearRange.to_string([1999, 2001, 2003]) == "1999, 2001, 2003"
    assert YearRange.to_string(["1998/1999", "2001/2002"]) == "1998-1999, 2001-2002"
  end
end
