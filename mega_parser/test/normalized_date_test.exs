defmodule MegaParser.NormalizedDateTest do
  use ExUnit.Case
  alias MegaParser.NormalizedDate
  doctest MegaParser.NormalizedDate

  test "to_string" do
    assert NormalizedDate.to_string(["1990-2000"], "1999-2005", nil) == "1990-2000, bulk 1999-2005"
    assert NormalizedDate.to_string(["1990", "1992"], "1999-2005", nil) == "1990, 1992, bulk 1999-2005"
    assert NormalizedDate.to_string(["1990-2000", "2001-2002", "2004"], "1990-2004", nil) == "1990-2002, 2004, bulk 1990-2004"
    assert NormalizedDate.to_string(["1990-2000", "2001-2002", "2004"], "n.d.", nil) == "1990-2002, 2004, bulk n.d."
    assert NormalizedDate.to_string(["1990-2000"], nil, nil) == "1990-2000"
    assert NormalizedDate.to_string(["Circa. 1990"], nil, nil) == "Circa. 1990"
    assert NormalizedDate.to_string(nil, "2004", nil) == nil
    assert NormalizedDate.to_string(nil, nil, "n.d.") == "n.d."
  end
end
